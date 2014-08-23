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
      # @param reader [Reader] An object that interprets and acts upon
      #   raw responses from the BAPS server.
      # @param request_queue [EventMachine::Queue] A queue that holds raw
      #   requests to the BAPS server.
      # @param logger [Object]  The logger, for logging errors.
      def initialize(reader, request_queue, logger)
        @reader         = reader
        @request_queue  = request_queue
        @logger         = logger
        @closing        = false
      end

      def post_init
        # Initiate the request queue pumping loop.
        pop_queue
      end

      # Send all data to the parser.
      def_delegator :@reader, :receive_data

      # Handles a successful connection completion
      #
      # @api semipublic
      # @example  Tell the Connection it's finished.
      #   conn.connection_completed
      #
      # @return [void]
      #
      def connection_completed
        @closing = true
      end

      # Handles a connection loss
      #
      # @api semipublic
      # @example  Tell the Connection it's died.
      #   conn.unbind
      #
      # @return [void]
      #
      def unbind
        unless @closing
          @logger.fatal('Lost connection to BAPS, dying.')
          EventMachine.stop
        end
      end

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
      # This will eventually call on_queue_pop with the data, once there is
      # some in the queue.
      #
      # @return [void]
      def pop_queue
        @request_queue.pop(&method(:on_queue_pop))
      end
    end
  end
end
