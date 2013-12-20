require 'eventmachine'

require 'bra/baps/codes'
require 'bra/baps/connection'
require 'bra/baps/reader'
require 'bra/baps/responses/parser'

module Bra
  module Baps
    # A high-level representation of a client on the legacy BAPS server
    #
    # The BAPS driver connects to the BAPS server as a regular client on TCP
    # sockets.  The actual reading and writing is done by objects controlled by
    # the Client, which attaches to an input responder and output queue.
    class Client
      # Creates a BAPS client
      #
      # @api semipublic
      #
      # @example Creating a BAPS client.
      #   queue = EventMachine::Queue.new
      #   client = Bra::Baps::Client.new(
      #     queue,
      #     'localhost',
      #     1234,
      #     'example',
      #     'hunter2'
      #   )
      #
      # @param queue [Queue] The requests queue that will connect to this
      #   client.
      # @param hostname [String] The host of the BAPS server to which this will
      #   connect.
      # @param port [Fixnum] The port of the BAPS server to which this will
      #   connect.
      # @param username [String] The username with which the login will occur.
      # @param password [String] The password with which the login will occur.
      def initialize(queue, hostname, port, username, password)
        @hostname = hostname
        @port = port
        @username = username
        @password = password

        @channel = EventMachine::Channel.new
        @reader = Reader.new
        @parser = Responses::Parser.new(@channel, @reader)
        @queue = queue
      end

      # Runs the client
      #
      # @api semipublic
      #
      # @example Running a client with a responder.
      #   responder = Responder.new(model, queue)
      #   EventMachine.run do
      #     # ...
      #     client.run(responder)
      #     # ...
      #   end
      #
      # @param responder [Responder] The controller that should be registered
      #   to handle any responses coming from this client.
      #
      # @return [void]
      def run(responder)
        responder.register(@channel)
        @parser.start
        connect
      end

      private

      def connect
        EventMachine.connect(@hostname, @port, Connection, @reader, @queue)
      end
    end
  end
end
