module Rapid
  module Server
    # A request for authentication
    class AuthRequest
      # Initialises an AuthRequest
      #
      # It may be more convenient to use the .request method instead.
      #
      # @param authenticator [Object]  The Kankri (or compatible) authenticator
      #   object to use when validating credentials.
      # @param rack_request [Object]  The Rack authentication request from
      #   which credentials should be extracted.
      #
      def initialize(authenticator, rack_request)
        @authenticator = authenticator
        @rack_request  = rack_request
      end

      # Initialises and runs an AuthRequest
      #
      # See #initialize for details on which arguments to send here.
      def self.request(*args)
        AuthRequest.new(*args).run
      end

      # Runs an AuthRequest
      #
      # @return [Array] An array of privilege symbols.
      def run
        @authenticator.authenticate(*credentials)
      end

      private

      # Attempts to glean credentials from the Rack request
      def credentials
        fail_authentication unless has_credentials?
        @rack_request.credentials
      end

      # Throws an authentication failure exception
      def fail_authentication
        fail(Kankri::AuthenticationFailure)
      end

      # Checks whether the Rack request has credentials available
      def has_credentials?
        r = @rack_request
        r.provided? && r.basic? && r.credentials
      end
    end
  end
end
