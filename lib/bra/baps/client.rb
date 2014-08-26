require 'eventmachine'

require 'bra/baps/codes'
require 'bra/driver_common/connection'
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
      # @api      semipublic
      # @example  Creating a BAPS client.
      #   queue = EventMachine::Queue.new
      #   client = Bra::Baps::Client.new(queue, 'localhost', 1234)
      #
      # @param queue [Queue]
      #   The requests queue that will connect to this client.
      # @param logger [Logger]
      #   The logger, for logging error messages.
      # @param hostname [String]
      #   The host of the BAPS server to which this Client will connect.
      # @param port [Fixnum]
      #   The port of the BAPS server to which this Client will connect.
      def initialize(queue, logger, hostname, port)
        @hostname = hostname
        @port = port

        @channel = EventMachine::Channel.new
        @reader = Reader.new
        @parser = Responses::Parser.new(@channel, @reader)
        @queue = queue

        @connection_args = [@reader, @queue, logger]
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
        EventMachine.connect(@hostname, @port, Connection, *@connection_args)
      end
    end
  end
end
