require 'socket'
require 'eventmachine'

module Bra
  module Baps
    # Internal: A client implementation for the legacy BAPS protocol.
    class Connection < EM::Connection
      def initialize(parser, request_queue)
        @parser = parser
        @request_queue = request_queue

        cb = proc do |msg|
          send_data(msg)
          request_queue.pop(&cb)
        end

        request_queue.pop(&cb)
      end

      # Internal: Read and interpret a response from the BAPS server.
      def receive_data(data)
        @parser.receive_data data
      end
    end
  end
end
