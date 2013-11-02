require 'eventmachine'
require_relative 'codes'
require_relative 'connection'
require_relative 'response_parser'
require_relative 'reader'
require_relative 'commands'
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

        @channel = EventMachine::Channel.new
        @reader = Reader.new
        @parser = ResponseParser.new(@channel, @reader)
        @queue = queue
      end

      # Public: Starts a BAPS connection, logs into it, and then sets up the
      # given API controller to handle the responses.
      #
      # controller - The controller that should be registered to handle any
      #              responses coming from this client.
      #
      # Returns nothing.
      def run(controller)
        controller.register(@channel)
        EM.connect(@hostname, @port, Connection, @parser, @queue)
        Commands::Initiate.new.run(@queue)
      end
    end
  end
end
