require 'bra/driver_common/response_buffer'

describe Bra::DriverCommon::ResponseBuffer do
  let(:reader) { Bra::DriverCommon::ResponseBuffer.new }

  describe '#request' do
    it 'yields the request block with raw data, as soon as it appears' do
      callback = double(:callback)
      callback.should_receive(:a).with('TestBytes').ordered
      callback.should_receive(:b).with('MoreTestBytes').ordered
      callback.should_receive(:c).with('EvenMore').ordered

      # Add request first, provide enough bytes
      reader.request(9, &callback.method(:a))
      reader.add('TestBytesMore')

      # Add request first, do not provide enough bytes initially
      reader.request(13, &callback.method(:b))
      reader.add('Test')
      reader.add('Bytes')

      # Add request after data
      reader.add('EvenMore')
      reader.request(8, &callback.method(:c))
    end
  end

  describe '#packed_request' do
    it 'yields the request block with unpacked data, as soon as it appears' do
      callback = double(:callback)
      callback.should_receive(:a).with([2001]).ordered
      callback.should_receive(:b).with(['MoreTestBytes']).ordered
      callback.should_receive(:c).with([12, 34, 56]).ordered

      # Add request first, provide enough bytes
      reader.packed_request(4, 'N', &callback.method(:a))
      reader.add([2001].pack('N') + 'More')

      # Add request first, do not provide enough bytes initially
      reader.packed_request(13, 'a13', &callback.method(:b))
      reader.add('Test')
      reader.add('Bytes')

      # Add request after data
      reader.add([12, 34, 56].pack('nnn'))
      reader.packed_request(6, 'nnn', &callback.method(:c))
    end
  end
end
