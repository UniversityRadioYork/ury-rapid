require 'socket'
require 'eventmachine'

module Bra
  module Baps

    # An object that handles the connection from bra to the BAPS server
    class Connection < EventMachine::Connection
      extend Forwardable

      # Initialises the Connection
      #
      # @api public
      # @example Initialises the Connection.
      #   conn = Connection.new(parser, request_queue)
      #
      # @param response_parser [Parser] An object that interprets and acts upon
      #   raw responses from the BAPS server.
      # @param request_queue [EventMachine::Queue] A queue that holds raw
      #   requests to the BAPS server.
      def initialize(response_parser, request_queue)
        @response_parser = response_parser
        @request_queue = request_queue

        # Initiate the request queue pumping loop.
        pop_queue
      end

      # Send all data to the parser.
      def_delegator :@response_parser, :receive_data

      private

      # Callback to fire when the queue is popped
      #
      # @api private
      #
      # @param request [String] A raw request to send to the server.
      #
      # @return [void]
      def on_queue_pop(request)
        send_data(request)
        pop_queue
      end

      # Attempts to pop data off the requests queue
      #
      # This will eventually call on_queue_pop with the data, once there is some
      # in the queue.
      #
      # @return [void]
      def pop_queue
        @request_queue.pop(&method(:on_queue_pop))
      end
    end
  end
end
