require 'sinatra/base'
require 'eventmachine'
require 'json'

# Our simple hello-world app
class BAPSApiApp < Sinatra::Base
  def initialize(config, model, queue)
    super()

    @model = model
    @config = config
    @queue = queue
  end

  # TODO: Make this protection more granular.
  helpers do
    def require_permissions!(*keys)
      credentials = get_auth
      if credentials.nil?
        headers['WWW-Authenticate'] = 'Basic realm="Restricted Area"'
        halt 401, 'Not authorised\n'
      end

      unless credentials & keys == keys
        halt 403, 'Forbidden\n'
      end
    end

    def get_auth?
      @auth ||= Rack::Auth::Basic::Request.new(request.env)

      if [@auth.provided?, @auth.basic?, @auth.credentials].all?
        user, password = @auth.credentials
        entry = @config['users'][user]
        if entry.nil? || entry['password'] != password
          nil
        else
          entry['privileges']
        end
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

    channels = @model.channels
    summary = channels.map(&(method :channel_summary))
    summary.to_json
  end

  get '/channels/:id/?' do
    content_type :json

    summary = channel_summary(channel_from params)
    summary.to_json
  end

  get '/channels/:id/playlist/?' do
    content_type :json

    channel = channel_from params
    items = channel.items.map(&(method :item))
    items.to_json
  end

  get '/channels/:id/playlist/:index/?' do
    content_type :json

    channel = channel_from params
    single_item = item(channel.items[Integer(params[:index])])
    single_item.to_json
  end

  get '/channels/:id/player/?' do
    content_type :json

    channel = channel_from params
    summary = player_summary channel.player
    summary.to_json
  end

  get '/channels/:id/player/state/?' do
    content_type :json

    channel = channel_from params
    channel.player.state.to_json
  end

  get '/channels/:id/player/load_state/?' do
    content_type :json

    channel = channel_from params
    channel.player.load_state.to_json
  end

  get '/channels/:id/player/item/?' do
    content_type :json

    channel = channel_from params
    item = loaded_item(channel.player.item)
    item.to_json
  end

  get '/channels/:id/position/?' do
    content_type :json

    channel = channel_from params
    channel.position.to_json
  end

  get '/channels/:id/cue/?' do
    content_type :json

    channel = channel_from params
    channel.cue.to_json
  end

  get '/channels/:id/intro/?' do
    content_type :json

    channel = channel_from params
    channel.intro.to_json
  end

  private

  # Internal: Gets a channel from the request parameters.
  #
  # params - The Sinatra parameters hash.
  #
  # Returns the channel of the ID specified in the hash.
  def channel_from(params)
    @model.channel Integer(params[:id])
  end

  # Internal: Outputs a summary of a channel's state.
  #
  # channel - The channel whose state is to be summarised.
  #
  # Returns a hash representing the channel.
  def channel_summary(channel)
    {
      id: channel.id,
      items: (channel.items.map(&(method :item))),
      player: player_summary(channel.player)
    }
  end

  # Internal: Outputs a summary of a channel's player's state.
  #
  # player - The player whose state is to be summarised.
  #
  # Returns a hash representing the player.
  def player_summary(player)
    {
      state: player.state,
      load_state: player.load_state,
      item: loaded_item(player.item),
      position: player.position,
      cue: player.cue,
      intro: player.intro
    }
  end

  # Internal: Outputs a hash or symbolic representation of a loaded item,
  # depending on the nature of the channel's loading, or nil if no loaded item
  # exists.
  #
  # loaded - The loaded item whose representation is sought.
  #
  # Returns a hash representing loaded (if it is a normal item), a symbol
  #   (one of :loading or :load_failed), or nil if no item is loaded or being
  #   loaded.
  def loaded_item(loaded)
    loaded.is_a?(Bra::Item) ? item(loaded) : loaded
  end

  # Internal: Outputs a hash representation of an item.
  #
  # item - The item whose hash equivalent is sought.
  #
  # Returns a hash representing item.
  def item(item)
    {
      type: item.type,
      name: item.name
    }
  end
end

