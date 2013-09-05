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

  # Request runs on the reactor thread (with threaded set to false)
  get '/hello' do
    'Hello World'
  end

  get '/channels' do
    content_type :json

    channels = @model.channels.map &(method :channel_summary)
    channels.to_json
  end

  get '/channels/:id' do
    content_type :json

    channel = channel_summary @model.channel(id)
  end

  # Request runs on the reactor thread (with threaded set to false)
  # and returns immediately. The deferred task does not delay the
  # response from the web-service.
  get '/delayed-hello' do
    EM.defer do
      sleep 5
    end
    "I'm doing work in the background, but I am still free to take requests"
  end

  private

  # Internal: Outputs a summary of a channel's state.
  #
  # channel - The channel whose state is to be summarised.
  def channel_summary channel
    {
      id: channel.id,
      state: channel.state,
      items: channel.items
    }
  end
end

