require 'socket'
require 'eventmachine'

module Rapid
  module Baps
    # An object that handles the connection from Rapid to a server
    class Connection < EventMachine::Connection
      extend Forwardable

      # Initialises the Connection
      #
      # @api public
      # @example Initialises the Connection.
      #   conn = Connection.new(parser, request_queue)
      #
      # @param in_reader [Reader] An object that interprets and acts upon
      #   raw responses from the server.
      # @param request_queue [EventMachine::Queue] A queue that holds raw
      #   requests to the server.
      # @param logger [Proc]  jhe logger, for logging errors.
      def initialize(in_reader, request_queue, logger)
        @reader         = in_reader
        @request_queue  = request_queue
        @logger         = logger
        @closing        = false
      end

      def post_init
        # Initiate the request queue pumping loop.
        pop_queue
      end

      # Send all data to the parser.
      delegate %i(receive_data) => :reader

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
      # @todo Make Rapid able to handle this instead of just dying
      #
      def unbind
        return if @closing
        @logger.call(:fatal, 'Lost connection, dying.')
        EventMachine.stop
      end

      private

      attr_reader :reader

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
