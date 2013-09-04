require 'socket'
require 'eventmachine'

# Public: Miscellaneous low-level interface code to the BAPS server.
module Bra
  # Public: Enumeration of the codes used by BAPS to refer to configuration
  # parameter types.
  module ConfigTypes
    INT = 0
    STR = 1
    CHOICE = 2
  end

  # Public: Enumeration of the codes used by BAPS to refer to track types.
  module TrackTypes
    NULL = 0
    FILE = 1
    LIBRARY = 2
    TEXT = 3
  end

  # Internal: A client implementation for the legacy BAPS protocol.
  #
  class BapsClient < EM::Connection
    # Internal: An object which can be used to parse and distribute responses
    # from the BAPS server.
    attr_reader :parser

    # Internal: A queue of requests to send to the server.
    attr_reader :request_queue

    def initialize(parser, request_queue)
      @parser = parser

      @request_queue = request_queue

      cb = Proc.new do |msg|
        send_data(msg)
        request_queue.pop &cb
      end

      request_queue.pop &cb
    end

    # Internal: Read and interpret a response from the BAPS server.
    def receive_data(data)
      parser.receive_data data
    end
  end

  # Internal: A low-level reading interface to the BAPS meta-protocol.
  #
  # The BapsReader works by operating on an internal buffer which can have
  # new data fed to it.
  class BapsReader
    # Internal: Creates a BapsReader.
    def initialize
      @buffer = ''
    end

    # Internal: Adds more data to the internal buffer.
    #
    # data - A string of data bytes to add to the processing buffer.
    #
    # Returns nothing.
    def add(data)
      @buffer << data
    end

    # Internal: Reads a command word.
    #
    # This does *not* read the rest of the command.  Use the other functions of
    # BapsReader to read parts of commands, and consider the Responses module
    # for higher level operations on BAPS responses.
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
      @socket.recv num_bytes
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

    # Internal: Reads a Pascal-style length-prefixed string.
    def string
      length = uint32
      if length.nil?
        nil
      else
        result = raw_bytes length
        if result.nil?
          # We need to put the length back on so the whole string can be read
          # again when we get enough data.
          @buffer << ([length].pack FormatStrings::UINT32)
          nil
        else
          puts "STRING: #{result}"
          result
        end
      end
    end

    private

    # Internal: Reads a given number of bytes and unpacks the result according
    # to the given format string.
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
    # unpack_format.
    def unpack(count, unpack_format)
      list = unpack_multi count, unpack_format
      list.nil? ? nil : list[0]
    end

    # Internal: Reads a given number of bytes and unpacks the results according
    # to the given format string.
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
      bytes = raw_bytes count
      bytes.nil? ? nil : (bytes.unpack unpack_format)
    end

    # Internal: Reads a given number of raw bytes from the buffer.
    #
    # count - The number of bytes to read.
    #
    # Returns the received bytes as a string, or nil if the number of bytes in
    # the buffer is less than count.
    def raw_bytes(count)
      buffer_size = @buffer.bytesize
      if buffer_size < count then
        nil
      else
        result = @buffer.byteslice(0...count)
        @buffer = @buffer.byteslice(count..buffer_size)
        result
      end
    end
  end

  # Internal: A message to be written to the BAPS server.
  class BapsRequest
    def initialize(command)
      # Format is initially set up for the command and the skip-bytes field.
      @format = FormatStrings::UINT16 + FormatStrings::UINT32
      @num_bytes = 0
      @payloads = []
      @command = command
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
    def send(queue)
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

  private

  # Internal: Constants for the various pack/unpack format strings the low
  # level interfaces use.
  module FormatStrings
    UINT16 = 'n'
    UINT32 = 'N'
    FLOAT32 = 'g'
    STRING_BODY = 'a'
  end
end
