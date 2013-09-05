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

  get '/channels/:id/state' do
    content_type :json

    channel = channel_from params
    channel.state.to_json
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
      items: (channel.items.map(&(method :item)))
    }
  end

  # Internal: Outputs a hash representation of an item.
  #
  # item - The item whose hash equivalent is sought.
  def item(item)
    {
      type: item.type,
      name: item.name
    }
  end
end

