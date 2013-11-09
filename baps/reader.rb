require 'active_support/core_ext/object/try'
require_relative 'format_strings'

module Bra
  module Baps
    # Internal: A low-level reading interface to the BAPS meta-protocol.
    #
    # The BapsReader works by operating on an internal buffer which can have
    # new data fed to it.
    class Reader
      # Internal: Creates a BapsReader.
      def initialize
        @buffer = ''
      end

      # Internal: Adds more data to the internal buffer.
      #
      # data - A string of data bytes to add to the processing buffer.
      #
      # @return [void]
      def add(data)
        @buffer << data
      end

      # Internal: Reads a command word.
      #
      # This does *not* read the rest of the command.  Use the other functions
      # of BapsReader to read parts of commands, and consider the Responses
      # module for higher level operations on BAPS responses.
      #
      # Returns nil (if the buffer is empty) or a list containing the following
      # data:
      #   - A 16-bit integer containing the BAPS command code;
      #   - A 32-bit integer providing the number of bytes following.  This
      #     cannot be relied upon to be accurate.
      def command
        unpack_multi 6, (FormatStrings::UINT16 + FormatStrings::UINT32)
      end

      # Internal: Receives and discards a number of bytes.
      def skip(num_bytes)
        @socket.recv(num_bytes)
        nil
      end

      # Internal: Reads a 16-bit unsigned integer.
      def uint16
        unpack 2, FormatStrings::UINT16
      end

      # Internal: Reads a 32-bit unsigned integer.
      def uint32
        unpack 4, FormatStrings::UINT32
      end

      # Internal: Reads a 32-bit (single-precision) floating-point number.
      def float32
        unpack 4, FormatStrings::FLOAT32
      end

      # Internal: Reads a given number of raw bytes from the buffer.
      #
      # count - The number of bytes to read.
      #
      # Returns the received bytes as a string, or nil if the number of bytes
      #   in the buffer is less than count.
      def raw_bytes(count)
        buffer_size = @buffer.bytesize
        if buffer_size < count
          nil
        else
          result = @buffer.byteslice(0...count)
          @buffer = @buffer.byteslice(count..buffer_size)
          result
        end
      end

      private

      # Internal: Reads a given number of bytes and unpacks the result
      # according to the given format string.
      #
      # This is for unpacking single items of data; for multiple items see
      # unpack_multi.
      #
      #
      # count         - The number of bytes to read.
      # unpack_format - The String#unpack format to use when interpreting the
      #                 contents of the bytes read.
      #
      # Returns the unpacked equivalent of the bytes read; the type depends on
      #   unpack_format.
      def unpack(count, unpack_format)
        list = unpack_multi(count, unpack_format)
        list.try(:first)
      end

      # Internal: Reads a given number of bytes and unpacks the results
      # according to the given format string.
      #
      # This is for unpacking multiple items of data; for multiple items see
      # unpack.
      #
      #
      # count         - The number of bytes to read.
      # unpack_format - The String#unpack format to use when interpreting the
      #                 contents of the bytes read.
      #
      # Returns the unpacked equivalent of the bytes read, as a list.
      def unpack_multi(count, unpack_format)
        bytes = raw_bytes(count)
        bytes.try(:unpack, unpack_format)
      end
    end
  end
end
