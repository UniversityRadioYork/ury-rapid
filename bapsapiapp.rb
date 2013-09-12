require 'sinatra/base'
require 'eventmachine'
require 'json'

# Our simple hello-world app
class BAPSApiApp < Sinatra::Base
  use Rack::MethodOverride

  def initialize(config, view, commander_maker)
    super()

    @view = view
    @config = config
    @commander = commander_maker.call(method :client_error)
  end

  # TODO: Make this protection more granular.
  helpers do
    def require_permissions!(*keys)
      credentials = get_auth
      if credentials.nil?
        headers['WWW-Authenticate'] = 'Basic realm="Restricted Area"'
        halt(401, json_error('Not authorised.'))
      end

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

  # threaded - False: Will take requests on the reactor thread
  #            True:  Will queue request for background thread
  configure do
    set :threaded, false
  end

  get '/channels/?' do
    content_type :json
    @view.channels.to_json
  end

  get '/channels/:id/?' do
    content_type :json
    @view.channel_at(params[:id]).to_json
  end

  get '/channels/:id/playlist/?' do
    content_type :json
    @view.playlist_for_channel_at(params[:id]).to_json
  end

  delete '/channels/:id/playlist/?' do
    content_type :json

    require_permissions!('EditPlaylist')
    @commander.run(:ClearPlaylist, params[:id])
    ok
  end

  get '/channels/:id/playlist/:index/?' do
    content_type :json
    @view.playlist_item_for_channel_at(params[:id], params[:index]).to_json
  end

  get '/channels/:id/player/?' do
    content_type :json
    @view.player_for_channel_at(params[:id]).to_json
  end

  get '/channels/:id/player/state/?' do
    content_type :json
    @view.player_state_for_channel_at(params[:id]).to_json
  end

  put '/channels/:id/player/state/?' do
    content_type :json

    require_permissions!('SetPlayerState')
    parse_json_from(request) do |body|
      @commander.run(:SetPlayerState, params[:id], body['state'])
      ok
    end
  end

  get '/channels/:id/player/load_state/?' do
    content_type :json
    @view.player_load_state_for_channel_at(params[:id]).to_json
  end

  get '/channels/:id/player/item/?' do
    content_type :json
    @view.player_item_for_channel_at(params[:id]).to_json
  end

  get '/channels/:id/player/position/?' do
    content_type :json
    @view.player_position_for_channel_at(params[:id]).to_json
  end

  put '/channels/:id/player/position/?' do
    require_permissions!('SetPlayerPosition')

    parse_json_from(request) do |body|
      @commander.run(:SetPlayerPosition, params[:id], body['position'])
      ok
    end
  end

  get '/channels/:id/player/cue/?' do
    content_type :json
    @view.player_cue_for_channel_at(params[:id]).to_json
  end

  get '/channels/:id/player/intro/?' do
    content_type :json
    @view.player_intro_for_channel_at(params[:id]).to_json
  end

  private

  # Internal: Retrieves the privileges available for a given user and password
  # combination.
  #
  # username - The username given by the user agent.
  # password - The password given by the user agent.
  #
  # Returns the set of privileges granted to this username and password.  If
  #   the username or password is incorrect, then no privileges are given.
  def privileges_for(username, password)
    entry = @config['users'][username]
    if entry.nil? || entry['password'] != password
      []
    else
      entry['privileges']
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
    halt 400, json_error('Badly formed JSON.')
  else
    yield json
  end

  # Internal: Flags a client error.
  #
  # message - The error message.
  #
  # Returns nothing.
  def client_error(message)
    halt 400, json_error(message)
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
