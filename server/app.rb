require 'sinatra/base'
require 'sinatra/contrib'
require 'sinatra/streaming'
require 'sinatra-websocket'
require 'eventmachine'
require 'json'
require 'haml'
require_relative '../common/payload'
require_relative 'updater'


module Bra
  # The Sinatra application that powers the server component of bra.
  module Server
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

      helpers Sinatra::Streaming

      # TODO: Make this protection more granular.
      helpers do
        # Gets the set of privileges the user has
        #
        # This fails with HTTP 401 if the user does not exist.
        #
        # @param requisites [Array] An optional array of required privileges; a
        #   HTTP exception shall be thrown if the user privileges don't match up.
        #
        # @return [Array] An array of privilege symbols.
        def privilege_set
          credentials = get_credentials(rack_auth)
          @authenticator.authenticate(*credentials)
        rescue Bra::Exceptions::AuthenticationFailure
          not_authorised
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
          halt(403, json_error('Forbidden.'))
        end

        # Fails with a HTTP 401 Not Authorised status.
        #
        # @return [void]
        def not_authorised
          headers['WWW-Authenticate'] = 'Basic realm="Restricted Area"'
          halt(401, json_error('Not authorised.'))
        end
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
      get('/') { respond_with :index }
      get('/stylesheets/*') { serve_text('css', 'stylesheets') }
      get('/scripts/*') { serve_text('javascript', 'scripts') }

      get('/stream/?') { model_updates_stream }

      # General model traversals.  These need to be at the bottom, so that they
      # don't override more specific URL matches.
      get('/*/?') { model_traversal { |target| handle_get(target) } }
      put('/*/?') { model_traversal_with_payload(:put) }
      post('/*/?') { model_traversal_with_payload(:post) }
      delete('/*/?') { model_traversal_without_payload(:delete) }

      private

      def serve_text(type, directory)
        content_type "text/#{type}", charset: 'utf-8'
        filename = params[:splat].first
        send_file File.join(settings.root, 'assets', directory, filename)
      end

      # Sets up a connection to the model updates stream.
      def model_updates_stream
        cors
        updater = Updater.new(@model, privilege_set)
        request.websocket? ? websocket_update(updater) : stream_update(updater)
      end

      def stream_update(updater)
        content_type 'application/json', charset: 'utf-8'
        stream(:keep_open, &updater.method(:stream))
      end

      def websocket_update(updater)
        request.websocket(&updater.method(:websocket))
      end

      def handle_get(target)
        get_repr = target.get(privilege_set)

        sym = target.class.name.demodulize.underscore.intern
        respond_with sym, get_repr do |f|
          f.html { handle_get_html(sym, target, get_repr) }
        end
      end

      def handle_get_html(sym, target, get_repr)
        haml(:object, locals: handle_get_html_locals(sym, target, get_repr))
      end

      def handle_get_html_locals(sym, target, get_repr)
        {
          resource_url: target.url,
          resource_id: target.id,
          resource_type: sym,
          resource: get_repr,
          inner: false
        }
      end

      def model_traversal_with_payload(action)
        model_traversal do |target|
          payload = make_payload(action, privilege_set, request, target)
          target.send(action, payload)
        end
      end

      def model_traversal_without_payload(action)
        model_traversal { |target| target.send(action, privilege_set) }
      end

      # Performs a model traversal, complete with CORS and privilege check
      def model_traversal(&block)
        cors
        find(params, &block)
      rescue Bra::Exceptions::InsufficientPrivilegeError
        forbidden
      end

      def find(params)
        @model.find_url(params[:splat].first) { |resource| yield(resource) }
      rescue Exceptions::MissingResourceError
        halt(404, json_error('Not found.'))
      end

      def make_payload(action, privilege_set, request, target)
        raw_payload = parse_json_from(request.body.string)
        Bra::Common::Payload.new(
          raw_payload, privilege_set,
          (action == :put ? target.id : target.default_id)
        )
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
        halt(400, json_error('Badly formed JSON.'))
      else
        json.deep_symbolize_keys!
      end

      # Internal: Flags a client error.
      #
      # message - The error message.
      #
      # @return [void]
      def client_error(message)
        halt(400, json_error(message))
      end

      # Internal: Renders an error message in JSON.
      #
      # message - The error message.
      #
      # Returns the JSON-padded equivalent.
      def json_error(message)
        { status: :error, error: message }.to_json
      end

      # Internal: Returns a "request sent OK" message.
      #
      # Returns some JSON.
      def ok
        { status: :ok }.to_json
      end
    end
  end
end
