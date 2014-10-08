require 'sinatra-websocket'

module Sinatra
  # Extends Sinatra's requests to include WebSocket extensions
  #
  # This doesn't seem to happen by default in some cases.
  class Request
    include SinatraWebsocket::Ext::Sinatra::Request
  end
end

module Rapid
  module Server
    module Helpers
      # Sinatra helper for HTTP and WebSocket update streaming
      # 
      # This depends on the Sinatra::Streaming helper set.
      module Streaming

        # Sets up a connection to the model updates stream.
        def model_updates_stream
          send(request.websocket? ? :websocket_update : :stream_update)
        end

        def stream_update
          content_type 'application/json', charset: 'utf-8'
          privs = privilege_set
          stream(:keep_open) { |s| StreamUpdater.launch(@model, s, privs) }
        end

        def websocket_update
          privs = privilege_set(true)
          request.websocket do |websocket|
            WebSocketUpdater.launch(
              @model, websocket, @authenticator.method(:authenticate), privs
            )
          end
        end
      end
    end
  end
end
