require 'ury_rapid/server'
require 'kankri'

module Rapid
  module Server
    module Helpers
      # Sinatra helpers for using Rapid's auth system in the HTTP server
      #
      # This depends on methods available in Rapid::Server::Helpers::Error.
      module Auth
        # Gets the set of privileges the user has
        #
        # This fails with HTTP 401 if the user does not exist.
        #
        # @return [Array] An array of privilege symbols.  If suppress_error is
        #   true and an authentication failure occurs, this may be nil.
        def privilege_set(suppress_error = false)
          rack_auth = Rack::Auth::Basic::Request.new(request.env)
          AuthRequest.request(@authenticator, rack_auth)
        rescue Kankri::AuthenticationFailure
          not_authorised unless suppress_error
        end

        # Fails with a HTTP 401 Not Authorised status.
        #
        # @return [void]
        def not_authorised
          headers['WWW-Authenticate'] = 'Basic realm="Restricted Area"'
          error(401, 'Not authorised.')
        end
      end
    end
  end
end
