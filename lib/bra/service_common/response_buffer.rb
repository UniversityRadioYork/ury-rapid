module Bra
  module ServiceCommon
    # A simple buffer for binary playout system responses
    #
    # The ResponseBuffer takes in requests for binary data, and fulfils them
    # as soon as it has enough data in its buffer.
    #
    # The ResponseBuffer is *not* thread-safe.
    class ResponseBuffer
      # Creates a Reader
      def initialize
        @buffer = ''
        @requests = []
        @satisfying_requests = false
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
      def packed_request(num_bytes, format, front = false, &block)
        request(num_bytes, front) { |bytes| block.call(bytes.unpack(format)) }
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
      # @param front [Boolean]  If true, the request is added onto the front
      #   of the queue, rather than the back.  This should be used for
      #   nested requests.
      #
      # @yieldparam bytes [String]  The bytes received.
      #
      # @return [void]
      def request(num_bytes, front = false, &block)
        @requests << [num_bytes, block] unless front
        @requests.unshift([num_bytes, block]) if front
        try_satisfy_requests unless @satisfying_requests
      end

      # Adds more data to the internal buffer
      #
      # @param [String] data  Data bytes to add to the processing buffer.
      #
      # @return [void]
      def add(data)
        @buffer << data
        try_satisfy_requests unless @satisfying_requests
      end

      alias_method :receive_data, :add

      private

      # Tries to satisfy as many requests for data as possible
      #
      # @return [void]
      def try_satisfy_requests
        @satisfying_requests = true
        can_satisfy = true
        while can_satisfy && !@requests.empty?
          request = @requests.first
          can_satisfy = try_satisfy_request(request)
          @requests.delete(request) if can_satisfy
        end
        @satisfying_requests = false
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
