require 'sinatra/base'
require 'sinatra/contrib'
require 'eventmachine'
require 'json'

module Bra
  class ServerApp < Sinatra::Base
    register Sinatra::Contrib
    use Rack::MethodOverride

    respond_to :html, :json, :xml

    def initialize(config, model, commander_maker)
      super()

      @model = model
      @config = config
      @commander = commander_maker.call(method :client_error)
    end

    # TODO: Make this protection more granular.
    helpers do
      def require_permissions!(keys)
        credentials = get_auth
        fail_not_authorised if credentials.nil?
        halt(403, json_error('Forbidden.')) unless (credentials & keys) == keys
      end

      def get_auth
        @auth ||= Rack::Auth::Basic::Request.new(request.env)

        if @auth.provided? && @auth.basic? && @auth.credentials
          user, password = @auth.credentials
          privileges_for(user, password)
        else
          nil
        end
      end
    end

    # Internal - Fails with a HTTP Not Authorised status.
    #
    # Returns nothing.
    def fail_not_authorised
      headers['WWW-Authenticate'] = 'Basic realm="Restricted Area"'
      halt(401, json_error('Not authorised.'))
    end

    # threaded - False: Will take requests on the reactor thread
    #            True:  Will queue request for background thread
    configure do
      set :threaded, false
    end

    get('/') { respond_with :index }
    get '/stylesheets/*' do
      content_type 'text/css', charset: 'utf-8'
      filename = params[:splat].first
      send_file File.join(settings.root, 'assets', 'stylesheets', filename)
    end
    get('/*/?') do
      find(params) do |resource|
        require_permissions!(resource.get_privileges)

        sym = resource.internal_name
        respond_with sym, resource.get do |f|
          f.html { haml(sym, locals: { sym => resource }) }
        end
      end
    end
    # put('/*/?') do
    #   find(params) do |resource|
    #     require_permissions!(resource.put_privileges)

    #   end
    # end

    def find(params)
      found = false

      @model.find_resource(params[:splat].first).try do |resource|
        yield(resource)
        found = true
      end

      halt(404, json_error('Not found.')) unless found
    end

    delete '/channels/:id/playlist/?' do
      content_type :json

      require_permissions!('EditPlaylist')
      @commander.run(:ClearPlaylist, params[:id])
      ok
    end

    put '/channels/:id/player/state/?' do
      content_type :json

      require_permissions!('SetPlayerState')
      parse_json_from(request) do |body|
        @commander.run(:SetPlayerState, params[:id], body['state'])
        ok
      end
    end

    put '/channels/:id/player/position/?' do
      require_permissions!('SetPlayerPosition')

      parse_json_from(request) do |body|
        @commander.run(:SetPlayerPosition, params[:id], body['position'])
        ok
      end
    end


    private

    # Internal: Retrieves the privileges available for a given user and
    # password combination.
    #
    # username - The username given by the user agent.
    # password - The password given by the user agent.
    #
    # Returns the set of privileges granted to this username and password.  If
    #   the username or password is incorrect, then no privileges are given.
    def privileges_for(username, password)
      entry = @config[:users][username.intern]
      if entry.nil? || entry[:password] != password
        []
      else
        entry[:privileges].map(&:intern)
      end
    end

    # Internal: Parses the request body as JSON and throws a 400 status if it
    # is malformed.
    #
    # request - The request whose body is to be parsed.
    #
    # Yields the parsed request body.
    #
    # Returns the block's return value if the JSON is valid, and nothing
    #   otherwise (processing is halted).
    def parse_json_from(request)
      json = JSON.parse(request.body.string)
    rescue JSON::ParserError
      halt(400, json_error('Badly formed JSON.'))
    else
      yield json
    end

    # Internal: Flags a client error.
    #
    # message - The error message.
    #
    # Returns nothing.
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
