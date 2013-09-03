require 'digest'

module Bra
  # Public: High-level versions of BAPS commands.
  #
  # These command classes are intended to be composable and accessible by
  # clients, but translate down into native BAPS command phrases.
  module Commands
    # Internal: The BAPS command codes used when translating codes down to
    # BAPS commands.
    module Codes
      SET_BINARY_MODE = 0xE600
      LOGIN = 0xE800

      SYNC = 0xE303
    end

    # Internal: The base class for all Command types.
    class Command
      # Internal: Dummy Run command.
      #
      # dispatch - Ignored.
      #
      # Returns nothing.
      def run(dispatch)
      end
    end

    # Public: A command that initiates communication with the BAPS server.
    #
    # This command is safe to use publicly, but consider using the Login
    # command instead.
    class Initiate < Command
      # Public: Runs an Initiate command on the given dispatcher.
      #
      # dispatch - The request/response dispatcher to use to send the command
      #            to the BAPS server on which the response should be received.
      #
      # Yields the seed given by the BAPS server for this session.  This seed
      #   should be passed into an Authenticate command.  Note that this yield
      #   is indirect and may occur some time after the call.
      #
      # Examples
      #
      #   Initiate.new.run dispatch { |seed| "The seed is: #{seed} "}
      #
      # Returns nothing.
      def run(dispatch)
        BapsRequest.new(Codes::SET_BINARY_MODE).send(dispatch.writer)
        dispatch.register(Responses::System::SEED) do |response|
          p response
          yield response[:seed]
          dispatch.deregister(response[:command])
        end
      end
    end

    # Public: A command that authenticates to the BAPS server.
    #
    # This command is safe to use publicly, but consider using the Login
    # command instead.
    class Authenticate < Command
      # Public: Error codes returned by the BAPS server upon authentication.
      module Errors
        OK = 0
        INCORRECT_USER = 1
        EMPTY_USER = 2
        INCORRECT_PASSWORD = 3
      end

      # Public: Initialise an Authenticate command.
      #
      # username - The password to use to authenticate to the BAPS server.
      # password - The (plaintext) password to use to authenticate to the BAPS
      #            server.
      # seed     - The session seed yielded by a previous Initiate command.
      def initialize(username, password, seed)
        @username = username
        @password = password
        @seed = seed
      end

      # Public: Runs an Authenticate command on the given dispatcher.
      #
      # dispatch - The request/response dispatcher to use to send the command
      #            to the BAPS server on which the response should be received.
      #
      # Yields the error code (see Authenticate::Errors) returned by the server
      #   on authentication, as well as the server's human-readable response
      #   string.  An error code of Authenticate::Errors::OK signifies a
      #   successful authentication.  Note that this yield is indirect and may
      #   occur some time after this call.
      #
      # Returns nothing.
      def run(dispatch)
        password_hash = Digest::MD5.hexdigest(@password)
        full_hash = Digest::MD5.hexdigest(@seed + password_hash)

        cmd = BapsRequest.new(Codes::LOGIN).string(@username).string(full_hash)
        cmd.send(dispatch.writer)

        dispatch.register(Responses::System::LOGIN) do |response|
          yield response[:subcode], response[:details]
          dispatch.deregister(response[:command])
        end
      end
    end

    # Public: Sets the BAPS server to send broadcast messages, as well as
    # making it forward the current server state to us.
    #
    # This command is safe to use publicly, but consider using the Login
    # command instead.
    class Synchronise < Command
      # Public: Runs a Synchronise command on the given dispatcher.
      #
      # This command takes no blocks, but will generate a very high number of
      # requests from the server.
      #
      # dispatch - The request/response dispatcher to use to send the command
      #            to the BAPS server on which the response should be received.
      #
      # Returns nothing.
      def run(dispatch)
        BapsRequest.new(Codes::SYNC).send(dispatch.writer)
      end
    end

    # Public: Completes the full log-in procedure to associate a client with
    # the BAPS server.
    #
    # This command performs the same work as a chain of Initiate, Authenticate,
    # and Synchronise.
    class Login < Command
      def initialize(username, password)
        @username = username
        @password = password
      end

      # Public: Runs a Login command on the given dispatcher.
      #
      # dispatch - The request/response dispatcher to use to send the command
      #            to the BAPS server on which the response should be received.
      # block    - A block to execute upon the entire login process concluding.
      #            See below.
      #
      # Yields, indirectly, the authentication status code and explanation
      #   string; see Authenticate#run for details.  Note that the yield occurs
      #   inside a block itself yielded by the dispatch, and thus may occur
      #   quite some time after this call.
      def run(dispatch, &block)
        init = Initiate.new
        init.run(dispatch) { |seed| authenticate dispatch, seed, block }
      end

      private

      # Internal: Performs the Authenticate leg of the Login procedure.
      #
      # dispatch - The request/response dispatcher to use to send the command
      #            to the BAPS server on which the response should be received.
      # seed     - The seed from the server, to send to Authenticate.
      # block    - A block to execute upon the entire login process concluding.
      #            See below.
      #
      # Yields the authentication status code and explanation string; see
      #   Authenticate#run for details.
      #
      # Returns nothing.
      def authenticate(dispatch, seed, block)
        auth = Authenticate.new(@username, @password, seed)
        auth.run(dispatch) do |code, string|
          Synchronise.new.run(dispatch) if code == Authenticate::Errors::OK
          block.call code, string
        end
      end
    end
  end
end
