module Bra
  module DriverCommon
    # A simple buffer for binary playout system responses
    #
    # The ResponseBuffer takes in requests for binary data, and fulfils them
    # as soon as it has enough data in its buffer.
    class ResponseBuffer
      # Creates a Reader
      def initialize
        @buffer = ''
        @requests = []
      end

      # Adds a request for packed data to the request queue
      #
      # @api public
      # @example Asking for a 32-bit network-endian integer.
      #   @result = nil
      #   packed_request(4, 'N')
      #   reader.add([2001].pack('N'))
      #   @result
      #   #=> [2001]
      #
      # @param num_bytes [Integer]  The number of bytes to ask for.
      # @param format [String]  The format string to use when unpacking.
      #
      # @yieldparam unpacked [Array]  The unpacked data.
      #
      # @return [void]
      def packed_request(num_bytes, format, &block)
        request(num_bytes) { |bytes| block.call(bytes.unpack(format)) }
      end

      # Adds a request for a given number of bytes to the request queue
      #
      # @api public
      # @example Asking for 6 bytes.
      #   @result = nil
      #   reader.request(5) { |bytes| @result = bytes }
      #   reader.add('abcdefghi')
      #   @result
      #   #=> 'abcde'
      #
      # @param num_bytes [Integer]  The number of bytes to ask for.
      #
      # @yieldparam bytes [String]  The bytes received.
      #
      # @return [void]
      def request(num_bytes, &block)
        @requests << [num_bytes, block]
        try_satisfy_requests
      end

      # Adds more data to the internal buffer
      #
      # @param [String] data  Data bytes to add to the processing buffer.
      #
      # @return [void]
      def add(data)
        @buffer << data
        try_satisfy_requests
      end

      private

      # Tries to satisfy as many requests for data as possible
      #
      # @return [void]
      def try_satisfy_requests
        @requests = @requests.drop_while(&method(:try_satisfy_request))
      end

      # Tries to satisfy a request for data
      #
      # @return [Boolean]  True if the request was satisfied; false otherwise.
      def try_satisfy_request(request)
        num_bytes, block = request
        (num_bytes <= @buffer.bytesize).tap do |enough_bytes|
          block.call(shift_buffer(num_bytes)) if enough_bytes
        end
      end

      # Shifts the given number of bytes off the buffer.
      #
      # The calling code is expected to check the bytesize of the buffer first.
      #
      # @api private
      #
      # @param num_bytes [Integer]  The number of bytes to shift.
      #
      # @return [String]  The shifted bytes.
      def shift_buffer(num_bytes)
        result = @buffer.byteslice(0...num_bytes)
        @buffer = @buffer.byteslice(num_bytes..@buffer.bytesize)
        result
      end
    end
  end
end
