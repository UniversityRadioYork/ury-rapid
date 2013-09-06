require 'sinatra/base'
require 'eventmachine'
require 'json'

# Our simple hello-world app
class BAPSApiApp < Sinatra::Base
  def initialize(model)
    super

    @model = model
  end

  # threaded - False: Will take requests on the reactor thread
  #            True:  Will queue request for background thread
  configure do
    set :threaded, false
  end

  get '/channels' do
    content_type :json

    channels = @model.channels
    summary = channels.map(&(method :channel_summary))
    summary.to_json
  end

  get '/channels/:id' do
    content_type :json

    summary = channel_summary(channel_from params)
    summary.to_json
  end

  get '/channels/:id/playlist' do
    content_type :json

    channel = channel_from params
    items = channel.items.map(&(method :item))
    items.to_json
  end

  get '/channels/:id/state' do
    content_type :json

    channel = channel_from params
    channel.state.to_json
  end

  get '/channels/:id/loaded' do
    content_type :json

    channel = channel_from params
    item = loaded_item(channel.loaded)
    item.to_json
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
  def channel_summary(channel)
    {
      id: channel.id,
      state: channel.state,
      items: (channel.items.map(&(method :item))),
      loaded: loaded_item(channel.loaded)
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

