require "socket"

module FormatStrings
  UINT16 = 'n'
  UINT32 = 'N'
  FLOAT32 = 'g'
  STRING_BODY = 'a'
end

module ConfigTypes
  INT = 0
  STR = 1
  CHOICE = 2
end

# A low-level client implementation for the legacy BAPS meta-protocol.
class BapsClient
  attr_reader :reader, :writer

  def initialize(host, port, reader = BapsReader, writer = BapsWriter)
    @socket = TCPSocket.new host, port
    @reader = reader.new(@socket)
    @writer = writer.new(@socket)
  end
end

# A low-level reading interface to the BAPS meta-protocol.
#
# Since we can't easily predict the exact range of bytes when reading, a
# prepared response format similar to BapsRequest won't work.
class BapsReader
  def initialize(socket)
    @socket = socket
  end

  def command
    [uint16, uint32]
  end

  def config_setting
    config_type = uint32
    value = (
      case config_type
      when ConfigTypes::CHOICE
        uint32
      when ConfigTypes::INT
        uint32
      when ConfigTypes::STR
        string
      end
    )
    [config_type, value]
  end

  def skip(num_bytes)
    @socket.recv num_bytes
    nil
  end

  def uint16
    unpack 2, FormatStrings::UINT16
  end

  def uint32
    unpack 4, FormatStrings::UINT32
  end

  def float32
    unpack 4, FormatStrings::FLOAT32
  end

  def string
    length = uint32
    @socket.recv length
  end

  private
  def unpack(num_bytes, unpack_format)
    bytes = @socket.recv num_bytes
    bytes.unpack(unpack_format)[0]
  end
end

# A writing interface to the BAPS protocol.
class BapsWriter
  def initialize(socket)
    @socket = socket
  end

  def write(bytes)
    while bytes.length > 0
      sent = @socket.send(bytes, 0)
      bytes = bytes[sent..-1]
    end
  end
end

# A message to be written to the BAPS server.
class BapsRequest
  def initialize(command)
    # Format is initially set up for the command and the skip-bytes field.
    @format = FormatStrings::UINT16 + FormatStrings::UINT32
    @num_bytes = 0
    @payloads = []
    @command = command
  end

  def uint16(payload)
    fixnum 2, FormatStrings::UINT16, payload
  end

  def uint32(payload)
    fixnum 4, FormatStrings::UINT32, payload
  end

  def string(payload)
    length = payload.length

    uint32 length

    @format << FormatStrings::STRING_BODY
    @format << length.to_s
    @num_bytes += length
    @payloads << payload

    self
  end

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
