require_relative 'codes'
require_relative 'connection'
require_relative 'response_parser'
require_relative 'reader'
require_relative 'commands'
require_relative 'dispatch'
require_relative 'responses'

module Bra
  module Baps
    # Public: A high-level representation of a client on the legacy BAPS
    # server.
    class Client
      # Public: Creates a BAPS client.
      # queue    - The requests queue that will connect to this client.
      # hostname - The host of the BAPS server to which this will connect.
      # port     - The port of the BAPS server to which this will connect.
      # username - The username with which the login will occur.
      # password - The password with which the login will occur.
      def initialize(queue, hostname, port, username, password)
        @hostname = hostname
        @port = port
        @username = username
        @password = password

        @dispatch = Dispatch.new
        @reader = Reader.new
        @parser = ResponseParser.new(@dispatch, @reader)
        @queue = queue
      end

      # Public: Starts a BAPS connection, logs into it, and then sets up the
      # given API controller to handle the responses.
      #
      # controller - The controller that should be registered to handle any
      #              responses coming from this client.
      #
      # Returns nothing.
      def start_with_controller(controller)
        start { |dispatch| controller.register(dispatch) }
      end

      # Public: Starts a BAPS connection and logs into it.
      #
      # block - An implicit block to be called if the login succeeds.
      #
      # Yields (indirectly) the dispatch and queue to the block.
      #
      # Returns nothing.
      def start(&block)
        EM.connect(@hostname, @port, Connection, @parser, @queue)
        login(&block)
      end

      private

      # Internal: Logs into the BAPS server and registers the dump functions.
      #
      # Yields the dispatch and queue to the block.
      #
      # Returns nothing.
      def login
        login = Commands::Login.new(@username, @password)
        login.run(@dispatch, @queue) do |error_code, error_string|
          login_succeeded = error_code == Commands::Authenticate::Errors::OK

          die(error_code, error_string) unless login_succeeded
          yield @dispatch, @queue if login_succeeded
        end
      end

      # Internal: Shuts down the BAPS client if login failed.
      #
      # error_code   - The code of the login error that occurred.  See
      #                Commands::Authenticate::Errors.
      # error_string - The server's description of the error that occurred.
      #
      # Returns nothing.
      def die(error_code, error_string)
        puts("Login failure: #{error_string} (code #{error_code}).")
        EM.stop
      end
    end
  end
end
