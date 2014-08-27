require 'rapid/baps/format_strings'
require 'rapid/service_common/response_buffer'

module Rapid
  module Baps
    # A low-level reading interface to the BAPS meta-protocol
    #
    # The Reader works by operating on an internal buffer which can have
    # new data fed to it.
    class Reader < ServiceCommon::ResponseBuffer
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

      # Requests that the Reader read a BAPS-formatted string
      #
      # The given block will be fired with the string as soon as it is read
      # into the Reader's buffer.
      #
      # @api      public
      # @example  Read a String, and print it out
      #   reader.string { |s| p s }
      #
      # @yieldparam [String]
      #   The read string.
      #
      # @return [void]
      def string 
        # BAPS strings are preceded by their length, Pascal-style.
        uint32 do |length|
          request(length, true) do |bytes|
            yield bytes
          end
        end
      end

      # Requests that the Reader read a BAPS command header
      #
      # A BAPS command is begun with a 16-bit command word, which is yielded
      # to the given block, and a 32-bit payload length, which is ignored (as
      # it is untrustworthy, and we hopefully need not skip payloads as we
      # understand every common BAPS command).
      #
      # @api      public
      # @example  Read a command word, and print it out
      #   reader.command { |word| p word }
      #
      # @yieldparam [Integer]
      #   The 16-bit command word as read from the header.
      #
      # @return [void]
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
