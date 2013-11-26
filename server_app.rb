require 'sinatra/base'
require 'sinatra/contrib'
require 'eventmachine'
require 'json'
require_relative 'common/payload'

module Bra
  ##
  # The Sinatra application that powers the server component of bra.
  class ServerApp < Sinatra::Base
    register Sinatra::Contrib
    use Rack::MethodOverride

    respond_to :html, :json, :xml

    def initialize(config, model, authenticator)
      super()

      @model = model
      @config = config
      @authenticator = authenticator
    end

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
        fail(Bra::Exceptions::AuthenticationFailure) unless has_credentials?(auth)
        auth.credentials
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

    options('/*/?') do
      cors
    end
    get('/') { respond_with :index }
    get '/stylesheets/*' do
      content_type 'text/css', charset: 'utf-8'
      filename = params[:splat].first
      send_file File.join(settings.root, 'assets', 'stylesheets', filename)
    end
    get '/scripts/*' do
      content_type 'text/javascript', charset: 'utf-8'
      filename = params[:splat].first
      send_file File.join(settings.root, 'assets', 'scripts', filename)
    end
    get('/*/?') do
      cors

      begin
        find(params) do |resource|
          get_repr = resource.get(privilege_set)

          sym = resource.class.name.demodulize.underscore.intern
          respond_with sym, get_repr do |f|
            f.html do
              haml(
                :object,
                locals: {
                  resource_url: resource.url,
                  resource_id: resource.id,
                  resource_type: sym,
                  resource: get_repr,
                  inner: false
                }
              )
            end
          end
        end
      rescue Bra::Exceptions::InsufficientPrivilegeError
        forbidden
      end
    end
    put('/*/?') { payload_action(:put) }
    post('/*/?') { payload_action(:post) }

    def payload_action(action)
      cors

      find(params) do |target|
        payload = make_payload(action, privilege_set, request, target)
        target.send(action, payload)
      end
    rescue Bra::Exceptions::InsufficientPrivilegeError
      forbidden
    end

    delete('/*/?') do
      cors

      begin
        find(params) { |resource| resource.delete(privilege_set) }
      rescue Bra::Exceptions::InsufficientPrivilegeError
        forbidden
      end
    end

    def find(params)
      @model.find_url(params[:splat].first) { |resource| yield(resource) }
    rescue Exceptions::MissingResourceError
      halt(404, json_error('Not found.'))
    end

    delete '/channels/:id/playlist/?' do
      content_type :json

      require_permissions!('EditPlaylist')
      @commander.run(:ClearPlaylist, params[:id])
      ok
    end

    private

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
      json = JSON.parse(request.body.string)
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
