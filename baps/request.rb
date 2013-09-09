require_relative 'format_strings'

module Bra
  module Baps
    # Internal: A message to be written to the BAPS server.
    class Request
      def initialize(command, subcode = 0)
        # Format is initially set up for the command and the skip-bytes field.
        @format = FormatStrings::UINT16 + FormatStrings::UINT32
        @num_bytes = 0
        @payloads = []
        @command = command | subcode
      end

      # Internal: Attaches a 16-bit integer to this request.
      def uint16(payload)
        fixnum 2, FormatStrings::UINT16, payload
      end

      # Internal: Attaches a 32-bit integer to this request.
      def uint32(payload)
        fixnum 4, FormatStrings::UINT32, payload
      end

      # Internal: Attaches a string to this request.
      def string(payload)
        length = payload.length

        uint32 length

        @format << FormatStrings::STRING_BODY
        @format << length.to_s
        @num_bytes += length
        @payloads << payload

        self
      end

      # Internal: Sends the request to a request queue.
      def to(queue)
        queue.push pack
      end

      private

      def pack
        ([@command, @num_bytes] + @payloads).pack(@format)
      end

      def fixnum(num_bytes, format_string, payload)
        @format << format_string
        @num_bytes += num_bytes
        @payloads << payload

        self
      end
    end
  end
end
