module Rapid
  module Server
    module Routing
      # Routes for serving the Rapid model
      #
      # Depends on the Server::Helpers::Model helper set.
      module Model
        # Registers the module routes
        def self.registered(app)
          # These routes match all of the server's URL namespace that hasn't
          # been reserved for other purposes.
          app.get('/*/?') { get }
          app.put('/*/?') { put }
          app.post('/*/?') { post }
          app.delete('/*/?') { delete }
        end
      end
    end
  end
end
