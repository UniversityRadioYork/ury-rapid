require_relative 'baps_connection.rb'
require_relative 'dispatch.rb'
require_relative 'responses.rb'

module Bra
  # Public: A high-level representation of a client on the legacy BAPS server.
  class BapsClient
    # Public: Creates a BAPS client.
    # hostname - The host of the BAPS server to which this will connect.
    # port     - The port of the BAPS server to which this will connect.
    # username - The username with which the login will occur.
    # password - The password with which the login will occur.
    def initialize(hostname, port, username, password)
      @hostname = hostname
      @port = port
      @username = username
      @password = password

      @dispatch = Dispatch.new
      @reader = BapsReader.new
      @parser = Responses::Parser.new @dispatch, @reader
      @queue = EM::Queue.new
    end

    # Public: Starts a BAPS connection and logs into it.
    #
    # block - An implicit block to be called if the login succeeds.
    #
    # Yields (indirectly) the dispatch and queue to the block.
    #
    # Returns nothing.
    def start(&block)
      EM.connect @hostname, @port, BapsConnection, @parser, @queue
      login &block
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

        die error_code, error_string unless login_succeeded
        yield @dispatch, @queue if login_succeeded
      end
    end

    # Internal: Shuts down the BAPS server if login failed.
    #
    # error_code   - The code of the login error that occurred.  See
    #                Commands::Authenticate::Errors.
    # error_string - The server's description of the error that occurred.
    #
    # Returns nothing.
    def die(error_code, error_string)
      puts "Login failure: #{error_string} (code #{error_code})."
      EM.stop
    end
  end
end
