module Rapid
  module Server
    module Routing
      # Routes for update streams
      #
      # Depends on the Server::Helpers::Streaming helper set.
      module Streaming
        # Registers the streaming routes
        def self.registered(app)
          # Serve the model updates stream under /stream.
          # Ignore any trailing slash.
          app.get('/stream/?') { model_updates_stream }
        end
      end
    end
  end
end
