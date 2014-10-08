module Rapid
  module Server
    module Helpers
      # Sinatra helpers for serving static files
      module Files
        def serve_text(type, directory)
          content_type "text/#{type}", charset: 'utf-8'
          filename = params[:splat].first
          send_file File.join(settings.root, 'assets', directory, filename)
        end
      end
    end
  end
end
