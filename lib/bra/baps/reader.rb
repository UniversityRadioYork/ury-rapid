require 'bra/baps/format_strings'
require 'bra/driver_common/response_buffer'

module Bra
  module Baps
    # A low-level reading interface to the BAPS meta-protocol
    #
    # The Reader works by operating on an internal buffer which can have
    # new data fed to it.
    class Reader < DriverCommon::ResponseBuffer
      # Create helpers for requesting BAPS primitive types.
      # Each type results in a one-member unpacked array, so discard the
      # array before yielding.
      PACKED_REQUESTS = {
        uint32:  [4, FormatStrings::UINT32],
        uint16:  [2, FormatStrings::UINT16],
        float32: [4, FormatStrings::FLOAT32]
      }
      PACKED_REQUESTS.each do |method, (bytes, fmt)|
        define_method(method) do |&block|
          packed_request(bytes, fmt) { |array| block.call(array.first) }
        end
      end

      def string
        uint32 do |length|
          request(length, true) do |bytes|
            yield bytes
          end
        end
      end

      def command(&block)
        uint16(&block)
        uint32 { |_| nil }  # Ignore the incoming data count.
      end

      private

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
