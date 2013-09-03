require 'socket'

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

  # Internal: A low-level client implementation for the legacy BAPS
  # meta-protocol.
  #
  class BapsClient
    # Internal: An object which can be used to read data from the BAPS server
    # in an unstructured manner.
    attr_reader :reader

    # Internal: An object which can be used to write data to the BAPS server.
    #
    # Usually BapsRequest objects are used to compose data for this writer.
    attr_reader :writer

    def initialize(host, port, reader = BapsReader, writer = BapsWriter)
      @socket = TCPSocket.new host, port
      @reader = reader.new(@socket)
      @writer = writer.new(@socket)
    end
  end

  # Internal: A low-level reading interface to the BAPS meta-protocol.
  #
  # Since we can't easily predict the exact range of bytes when reading, a
  # prepared response format similar to BapsRequest won't work.
  class BapsReader
    # Internal: Creates a BapsReader.
    #
    # socket - A TCPSocket through which the BapsReader should read data.
    def initialize(socket)
      @socket = socket
    end

    # Internal: Reads a command word.
    #
    # This does *not* read the rest of the command.  Use the other functions of
    # BapsReader to read parts of commands, and consider the Responses module
    # for higher level operations on BAPS responses.
    #
    # Returns a list containing the following data:
    #   - A 16-bit integer containing the BAPS command code;
    #   - A 32-bit integer providing the number of bytes following.  This
    #     cannot be relied upon to be accurate.
    def command
      [uint16, uint32]
    end

    # Internal: Reads a config setting.
    #
    # Config settings are one of the uglier areas of BAPS's meta-protocol, as
    # the format of the config value depends on the preceding config type.
    # As such, it's much easier to treat them as a single element.
    #
    # Returns a list with the following items:
    #   - The type of the config setting, as a member of ConfigTypes.
    #   - The actual config setting itself, as either an integer or a string
    #     depending on the type.  When the type is CHOICE, this is the ID of
    #     the selected choice.
    def config_setting
      config_type = uint32
      value = send CONFIG_TYPE_FUNCTIONS[config_type]
      [config_type, value]
    end

    # Internal: Reads the body of a LOAD command.
    #
    # LOAD commands change their format depending on the track type, so we
    # have to parse them specially.
    #
    # Returns a hash with the following keys:
    #   type: The track type, as a member of TrackTypes.
    def load_body
      track_type = uint32
      title = string
      body = { type: track_type, title: title }
      body.merge!({ duration: uint32 }) if track_type == TrackTypes::LIBRARY
      body
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
      raw_bytes length
    end

    private

    # Internal: Reads a given number of bytes and unpacks the result according
    # to the given format string.
    #
    # count         - The number of bytes to read.
    # unpack_format - The String#unpack format to use when interpreting the
    #                 contents of the bytes read.
    #
    # Returns the unpacked equivalent of the bytes read; the type depends on
    # unpack_format.
    def unpack(count, unpack_format)
      bytes = raw_bytes count
      bytes.unpack(unpack_format)[0]
    end

    # Internal: Reads a given number of raw bytes.
    #
    # count - The number of bytes to read.
    #
    # Returns the received bytes as a string.
    def raw_bytes(count)
      to_receive = count
      bytes = ''
      while 0 < to_receive
        new_bytes = @socket.recv to_receive
        to_receive -= new_bytes.length
        bytes << new_bytes
      end

      bytes
    end

    # Internal: A map of configuration types to the names of BapsReader
    # functions for reading them.
    CONFIG_TYPE_FUNCTIONS = {
      ConfigTypes::CHOICE => :uint32,
      ConfigTypes::INT => :uint32,
      ConfigTypes::STR => :string
    }
  end

  # A writing interface to the BAPS protocol.
  class BapsWriter
    def initialize(socket)
      @socket = socket
    end

    def write(bytes)
      while 0 < bytes.length
        sent = @socket.send(bytes, 0)
        bytes = bytes[sent..-1]
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

    # Internal: Sends the request to a BapsWriter for sending to the BAPS
    # client.
    def send(writer)
      writer.write pack
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
