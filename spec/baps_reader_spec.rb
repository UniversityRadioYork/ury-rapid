require 'bra/baps/reader'

describe Bra::Baps::Reader do
  let(:callback) { double(:callback) }

  before(:each) do
    callback.should_receive(:test).with(value).once
  end

  describe '#uint16' do
    context 'when called before a single, full data send' do
      let(:value) { 0 }
      it 'requests a 16-bit integer' do
        test_full_data(:uint16, Bra::Baps::FormatStrings::UINT16)
      end
    end
    context 'when called before an incremental data send' do
      let(:value) { 32767 }
      it 'requests a 16-bit integer' do
        test_split_data(:uint16, Bra::Baps::FormatStrings::UINT16)
      end
    end
    context 'when called after a single, full data send' do
      let(:value) { 65535 }
      it 'requests a 16-bit integer' do
        test_post_data(:uint16, Bra::Baps::FormatStrings::UINT16)
      end
    end
  end

  describe '#uint32' do
    context 'when called before a single, full data send' do
      let(:value) { 0 }
      it 'requests a 32-bit integer' do
        test_full_data(:uint32, Bra::Baps::FormatStrings::UINT32)
      end
    end
    context 'when called before an incremental data send' do
      let(:value) { 2_147_483_647 }
      it 'requests a 32-bit integer' do
        test_split_data(:uint32, Bra::Baps::FormatStrings::UINT32)
      end
    end
    context 'when called after a single, full data send' do
      let(:value) { 4_294_967_295 }
      it 'requests a 32-bit integer' do
        test_post_data(:uint32, Bra::Baps::FormatStrings::UINT32)
      end
    end
  end

  describe '#float32' do
    context 'when called before a single, full data send' do
      let(:value) { 0 }
      it 'requests a 32-bit floating-point number' do
        test_full_data(:float32, Bra::Baps::FormatStrings::FLOAT32)
      end
    end
    context 'when called before an incremental data send' do
      let(:value) { 0.125 }
      it 'requests a 32-bit floating-point number' do
        test_split_data(:float32, Bra::Baps::FormatStrings::FLOAT32)
      end
    end
    context 'when called after a single, full data send' do
      let(:value) { 512.0 }
      it 'requests a 32-bit floating-point number' do
        test_post_data(:float32, Bra::Baps::FormatStrings::FLOAT32)
      end
    end
  end

  describe '#string' do
    let(:value) { 'Fantasia in C Minor' }

    context 'when called before a single, full data send' do
      it 'requests a Pascal-format string and yields it when it appears' do
        subject.string { |string| callback.test(string) }
        subject.add([value.bytesize].pack('N') + value)
      end
    end

    context 'when called after a single, full data send' do
      it 'requests a Pascal-format string and yields it when it appears' do
        subject.add([value.bytesize].pack('N') + value)
        subject.string { |string| callback.test(string) }
      end
    end
  end

  def test_full_data(method, pack_format)
    subject.send(method, &callback.method(:test))
    subject.add([value].pack(pack_format))
  end

  def test_split_data(method, pack_format)
    subject.send(method, &callback.method(:test))
    ([value].pack(pack_format)).each_char(&subject.method(:add))
  end

  def test_post_data(method, pack_format)
    subject.add([value].pack(pack_format))
    subject.send(method, &callback.method(:test))
  end
end
