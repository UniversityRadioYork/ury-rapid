require 'ury-rapid/baps/format_strings'

module Rapid
  module Baps
    module Requests
      # A message to be written to the BAPS server
      #
      # Request objects are usually created by the Requester, either directly
      # or via Handler objects.  They capture a native BAPS command in a format
      # slightly higher in level than the raw bytes sent to the requests queue.
      class Request
        def initialize(command, subcode = 0)
          # Format is initially set up for the command and the skip-bytes
          # field.
          @format = FormatStrings::UINT16 + FormatStrings::UINT32
          @num_bytes = 0
          @payloads = []
          @command = command | subcode
        end

        # Internal: Attaches a 16-bit integer to this request.
        def uint16(*payloads)
          fixnums(2, FormatStrings::UINT16, payloads)
        end

        # Internal: Attaches a 32-bit integer to this request.
        def uint32(*payloads)
          fixnums(4, FormatStrings::UINT32, payloads)
        end

        # Internal: Attaches a 32-bit floating point number to this request.
        def float32(*payloads)
          fixnums(4, FormatStrings::FLOAT32, payloads)
        end

        # Adds strings to this request
        def string(*strings)
          strings.each(&method(:single_string))
          self
        end

        # Internal: Sends the request to a request queue.
        def to(queue)
          queue.push(pack)
        end

        private

        def single_string(string)
          length = string.length

          uint32(length)

          @format << FormatStrings::STRING_BODY
          @format << length.to_s
          @num_bytes += length
          @payloads << string
        end

        def pack
          ([@command, @num_bytes] + @payloads).pack(@format)
        end

        def fixnums(num_bytes, format_string, nums)
          nums.each { |num| fixnum(num_bytes, format_string, num) }
          self
        end

        def fixnum(num_bytes, format_string, payload)
          @format << format_string
          @num_bytes += num_bytes
          @payloads << payload
        end
      end
    end
  end
end
