module Rapid
  module Server
    module Routing
      # Routes for static files
      #
      # Depends on the Rapid::Server::Helpers::Files helper set.
      module Files
        # Registers the file routes
        def self.registered(app)
          # Serve all files under the /stylesheets directory as CSS.
          app.get('/stylesheets/*') { serve_text('css', 'stylesheets') }

          # Serve all files under the /scripts directory as JS.
          app.get('/scripts/*') { serve_text('javascript', 'scripts') }
        end
      end
    end
  end
end
