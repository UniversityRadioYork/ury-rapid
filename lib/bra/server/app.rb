require 'eventmachine'
require 'json'
require 'sinatra-websocket'
require 'sinatra/base'
require 'sinatra/contrib'
require 'sinatra/streaming'

require 'bra/common/payload'
require 'bra/server/inspector'
require 'bra/server/updater'

module Bra
  module Server
    # The Sinatra application that powers the server component of bra
    class App < Sinatra::Base
      register Sinatra::Contrib
      use Rack::MethodOverride

      respond_to :html, :json, :xml

      def initialize(config, model, authenticator)
        super()

        @model = model
        @config = config
        @authenticator = authenticator
      end

      helpers InspectorHelpers
      helpers Sinatra::Streaming

      # Gets the set of privileges the user has
      #
      # This fails with HTTP 401 if the user does not exist.
      #
      # @return [Array] An array of privilege symbols.  If suppress_error is
      #   true and an authentication failure occurs, this may be nil.
      def privilege_set(suppress_error = false)
        credentials = get_credentials(rack_auth)
        @authenticator.authenticate(*credentials)
      rescue Bra::Exceptions::AuthenticationFailure
        not_authorised unless suppress_error
      end

      def rack_auth
        Rack::Auth::Basic::Request.new(request.env)
      end

      def get_credentials(auth)
        fail_authentication unless has_credentials?(auth)
        auth.credentials
      end

      def fail_authentication
        fail(Bra::Exceptions::AuthenticationFailure)
      end

      def has_credentials?(auth)
        auth.provided? && auth.basic? && auth.credentials
      end

      # Fails with a HTTP 403 Forbidden status.
      # @return [void]
      def forbidden
        error(403, 'Forbidden.')
      end

      # Fails with a HTTP 401 Not Authorised status.
      #
      # @return [void]
      def not_authorised
        headers['WWW-Authenticate'] = 'Basic realm="Restricted Area"'
        error(401, 'Not authorised.')
      end

      # Handle CORS headers
      #
      # Such a senseless waste of precious bytes.
      #
      # @return [void]
      def cors
        @config[:cors].each do |header, items|
          headers "Access-Control-#{header}" => items.join(', ')
        end
      end

      # threaded - False: Will take requests on the reactor thread
      #            True:  Will queue request for background thread
      configure do
        set :threaded, false
      end

      # Respond to HTTP OPTIONS with CORS headers, to allow out-of-request
      # CORS checks.
      options('/*/?') { cors }

      # Special files.
      get('/stylesheets/*') { serve_text('css', 'stylesheets') }
      get('/scripts/*') { serve_text('javascript', 'scripts') }

      get('/stream/?') { model_updates_stream }

      # General model traversals.  These need to be at the bottom, so that they
      # don't override more specific URL matches.
      get('/*/?') { model_traversal { |target| handle_get(target) } }
      put('/*/?') { model_traversal_with_payload(:put) }
      post('/*/?') { model_traversal_with_payload(:post) }
      delete('/*/?') { model_traversal_with_payload(:delete) }

      private

      def serve_text(type, directory)
        content_type "text/#{type}", charset: 'utf-8'
        filename = params[:splat].first
        send_file File.join(settings.root, 'assets', directory, filename)
      end

      # Sets up a connection to the model updates stream.
      def model_updates_stream
        cors
        send(request.websocket? ? :websocket_update : :stream_update)
      end

      def stream_update
        content_type 'application/json', charset: 'utf-8'
        privs = privilege_set
        stream(:keep_open) do |stream|
          StreamUpdater.launch(@model, stream, privs)
        end
      end

      def websocket_update
        privs = privilege_set(true)
        request.websocket do |websocket|
          WebSocketUpdater.launch(
            @model, websocket, @authenticator.method(:authenticate), privs
          )
        end
      end

      def handle_get(target)
        get_repr = {
          status: :ok,
          value: target.get(privilege_set)
        }

        respond_with :json, get_repr do |f|
          f.html do
            inspector_haml(Inspector.new(request, target, privilege_set))
          end
        end
      end

      # Renders an API Inspector instance using HAML.
      def inspector_haml(inspector)
        haml(inspector.resource_type, locals: { inspector: inspector })
      end

      def model_traversal_with_payload(action)
        model_traversal do |target|
          payload = make_payload(action, privilege_set, request, target)
          target.send(action, payload)
        end
      end

      # Performs a model traversal, complete with CORS and privilege check
      def model_traversal(&block)
        cors
        find(params, &block)
      rescue Bra::Exceptions::InsufficientPrivilegeError
        forbidden
      rescue Bra::Exceptions::NotSupported => e
        not_supported(e)
      end

      def find(params, &block)
        @model.find_url(params[:splat].first, &block)
      rescue Exceptions::MissingResource
        error(404, 'Not found.')
      end

      def make_payload(action, privilege_set, request, target)
        raw_payload = get_raw_payload(request)
        Bra::Common::Payload.new(
          raw_payload, privilege_set,
          (action == :put ? target.id : target.default_id)
        )
      end

      def get_raw_payload(request)
        payload_string = request.body.string
        payload_string.empty? ? nil : parse_json_from(request.body.string)
      end

      # Parses the request body as JSON and throws a 400 status if it
      # is malformed.
      #
      # request - The request whose body is to be parsed.
      #
      # Yields the parsed request body.
      #
      # Returns the block's return value if the JSON is valid, and nothing
      #   otherwise (processing is halted).
      def parse_json_from(string)
        json = JSON.parse(string)
      rescue JSON::ParserError
        error(400, 'Badly formed JSON.')
      else
        json.deep_symbolize_keys!
      end

      # Flags a client error
      #
      # @param message [String] The error message.
      #
      # @return [void]
      def client_error(message)
        error(400, message)
      end

      # Halts due to an operation not being supported
      def not_supported(exception)
        error(405, exception.to_s)
      end

      # Halts with an error status code and message
      #
      # @param code [Integer]  The HTTP status code to return.
      # @param message [String]  A human-readable message to show the client.
      #
      # @return [void]
      def error(code, message)
        halt(code, render_error(code, message))
      end

      # Renders an error message
      #
      # @param code [Integer]  The HTTP status code to return.
      # @param message [String]  A human-readable message to show the client.
      #
      # @return [String]  The error message, rendered according to the client's
      #   Accept headers.
      def render_error(code, message)
        # This is a very hacky way of making respond_with resolve the correct
        # format for our error message, while stopping it from halting with
        # a 200 status code (we need to specify our own status code).
        catch(:halt) do
          respond_with(
            :error,
            { status: :error, error: message, http_code: code }
          )
        end
      end

      # Renders a 'request sent OK' message
      #
      # This should be used for PUT, POST and DELETE responses.  There is a
      # special handler for GET, and OPTIONS returns CORS headers.
      #
      # @return [String]  The OK message, rendered according to the client's
      #   Accept headers.
      def ok
        respond_with :ok, { status: :ok }
      end
    end
  end
end
