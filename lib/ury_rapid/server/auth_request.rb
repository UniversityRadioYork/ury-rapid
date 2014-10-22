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
        fail_authenticator_is_nil          if authenticator.nil?
        fail_authenticator_cannot_auth unless can_auth?(authenticator)

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

      # Checks whether an authenticaticator can auth
      # @api private
      def can_auth?(authenticator)
        authenticator.respond_to?(:authenticate)
      end

      # Fails with an error stating that the authenticator is nil
      # @api private
      def fail_authenticator_is_nil
        fail(ArgumentError, 'Authenticator is nil')
      end

      # Fails with an error stating that the authenticator can't authenticate
      # @api private
      def fail_authenticator_cannot_auth
        fail(ArgumentError, 'Authenticator cannot auth')
      end

      # Attempts to glean credentials from the Rack request
      def credentials
        fail_authentication unless credentials?
        @rack_request.credentials
      end

      # Throws an authentication failure exception
      def fail_authentication
        fail(Kankri::AuthenticationFailure)
      end

      # Checks whether the Rack request has credentials available
      def credentials?
        r = @rack_request
        r.provided? && r.basic? && r.credentials
      end
    end
  end
end
