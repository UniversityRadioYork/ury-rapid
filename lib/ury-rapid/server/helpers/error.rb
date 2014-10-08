require 'ury-rapid/common/exceptions'
require 'kankri'

module Rapid
  module Server
    module Helpers
      # Sinatra helpers for sending error messages to the client
      module Error
        # Wraps a block in various common error handlers
        def wrap
          yield
        rescue Kankri::InsufficientPrivilegeError
          error(403, 'Forbidden.')
        rescue Common::Exceptions::MissingResource
          error(404, 'Not found.')
        rescue Common::Exceptions::NotSupported => e
          not_supported(e)
        end

        # Flags a client error
        #
        # @param message [String] The error message.
        #
        # @return [void]
        def client_error(message)
          error(400, message)
        end

        # Halts due to an operation not being supported
        def not_supported(exception)
          error(405, exception.to_s)
        end

        # Halts with an error status code and message
        #
        # @param code [Integer]  The HTTP status code to return.
        # @param message [String]  A human-readable message to show the client.
        #
        # @return [void]
        def error(code, message)
          halt(code, render_error(code, message))
        end

        # Renders an error message
        #
        # @param code [Integer]  The HTTP status code to return.
        # @param message [String]  A human-readable message to show the client.
        #
        # @return [String]  The error message, rendered according to the client's
        #   Accept headers.
        def render_error(code, message)
          # This is a very hacky way of making respond_with resolve the correct
          # format for our error message, while stopping it from halting with
          # a 200 status code (we need to specify our own status code).
          catch(:halt) do
            respond_with(:error,
                         status: :error, error: message, http_code: code)
          end
        end
      end
    end
  end
end
