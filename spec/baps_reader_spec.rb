require 'bra/baps/reader'

# Representative values
UINT16_MIN = 0
UINT16_MID = 32_767
UINT16_MAX = 65_535
UINT16S = [UINT16_MIN, UINT16_MID, UINT16_MAX]

UINT32_MIN = 0
UINT32_MID = 2_147_483_647
UINT32_MAX = 4_294_967_295
UINT32S = [UINT32_MIN, UINT32_MID, UINT32_MAX]

# These are specifically numbers divisible by two, to avoid imprecision
FLOAT32_MIN = 0
FLOAT32_MID = 0.125
FLOAT32_MAX = 128.0
FLOAT32S = [FLOAT32_MIN, FLOAT32_MID, FLOAT32_MAX]

describe Bra::Baps::Reader do
  describe '#uint16' do
    it 'requests a 16-bit integer' do
      number_request(:uint16, UINT16S, Bra::Baps::FormatStrings::UINT16)
    end
  end
  describe '#uint32' do
    it 'requests a 32-bit integer' do
      number_request(:uint32, UINT32S, Bra::Baps::FormatStrings::UINT32)
    end
  end
  describe '#float32' do
    it 'requests a 32-bit floating point number' do
      number_request(:float32, FLOAT32S, Bra::Baps::FormatStrings::FLOAT32)
    end
  end
  # Tests method, with the given values, using the given format string
  def number_request(method, values, pack_format)
    min, mid, max = values

    callback = double(:callback)
    callback.should_receive(:a).with(min).ordered
    callback.should_receive(:b).with(mid).ordered
    callback.should_receive(:c).with(max).ordered

    # Request before full data
    subject.send(method, &callback.method(:a))
    subject.add([min].pack(pack_format))

    # Request before data in two instalments
    subject.send(method, &callback.method(:b))
    ([mid].pack(pack_format)).each_char(&subject.method(:add))

    # Request after data
    subject.add([max].pack(pack_format))
    subject.send(method, &callback.method(:c))
  end
end
