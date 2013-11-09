require_relative 'reader'

# Representative values
UINT16_MIN = 0
UINT16_MID = 32_767
UINT16_MAX = 65_535
UINT16S = [UINT16_MIN, UINT16_MID, UINT16_MAX]

UINT32_MIN = 0
UINT32_MID = 2_147_483_647
UINT32_MAX = 4_294_967_295
UINT32S = [UINT32_MIN, UINT32_MID, UINT32_MAX]

describe Bra::Baps::Reader do
  describe '#uint16' do
    context 'with no data' do
      it 'returns nil' do
        reader = Bra::Baps::Reader.new

        reader.uint16.should be_nil
      end
    end
    context 'with one datum' do
      it 'reads an unsigned 16-bit integer' do
        reader = Bra::Baps::Reader.new

        UINT16S.each do |n|
          reader.add([n].pack('n'))
          reader.uint16.should eq(n)
        end
      end
    end
    context 'with multiple data' do
      it 'reads unsigned 16-bit integers in order' do
        reader = Bra::Baps::Reader.new

        UINT16S.each { |n| reader.add([n].pack('n')) }
        UINT16S.each { |n| reader.uint16.should eq(n) }
      end
    end
  end

  describe '#uint32' do
    context 'with no data' do
      it 'returns nil' do
        reader = Bra::Baps::Reader.new

        reader.uint16.should be_nil
      end
    end
    context 'with one datum' do
      it 'reads an unsigned 32-bit integer' do
        reader = Bra::Baps::Reader.new

        UINT32S.each do |n|
          reader.add([n].pack('N'))
          reader.uint32.should eq(n)
        end
      end
    end
    context 'with multiple data' do
      it 'reads unsigned 32-bit integers in order' do
        reader = Bra::Baps::Reader.new

        UINT32S.each { |n| reader.add([n].pack('N')) }
        UINT32S.each { |n| reader.uint32.should eq(n) }
      end
    end
  end

  describe '#raw_bytes' do
    context 'with no data' do
      it 'returns nil' do
        reader = Bra::Baps::Reader.new

        reader.raw_bytes(10).should be_nil
      end
    end
    context 'with insufficient data' do
      it 'returns nil' do
        reader = Bra::Baps::Reader.new

        reader.add('The quick brown fox jumps over the lazy dog.')
        reader.raw_bytes(200).should be_nil
      end
    end
    context 'with sufficient data' do
      it 'reads the number of bytes requested' do
        reader = Bra::Baps::Reader.new

        str = 'The quick brown fox jumps over the lazy dog.'
        reader.add(str)
        reader.raw_bytes(str.bytesize).should eq(str)
        reader.raw_bytes(1).should be_nil
      end
    end
    context 'with more than enough data' do
      it 'reads the number of bytes requested' do
        reader = Bra::Baps::Reader.new

        reader.add('The quick brown fox jumps over the lazy dog.')
        reader.raw_bytes(10).should eq('The quick ')
        reader.raw_bytes(10).should eq('brown fox ')
        reader.raw_bytes(10).should eq('jumps over')
        reader.raw_bytes(10).should eq(' the lazy ')
        reader.raw_bytes(2).should eq('do')
        reader.raw_bytes(1).should eq('g')
        reader.raw_bytes(1).should eq('.')
        reader.raw_bytes(1).should be_nil
      end
    end
  end
end
