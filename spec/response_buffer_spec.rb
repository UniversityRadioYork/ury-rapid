require 'bra/driver_common/response_buffer'

describe Bra::DriverCommon::ResponseBuffer do
  describe '#request' do
    context 'when a request callback asks for a new immediate request' do
      it 'processes the two requests in order' do
        callback = double(:callback)
        expect(callback).to receive(:a).with('MoreBytes').ordered
        expect(callback).to receive(:b).with('Please').ordered

        subject.request(4) do |bytes|
          expect(bytes).to eq('Test')
          subject.request(9, true, &callback.method(:a))
        end
        subject.request(6, &callback.method(:b))
        subject.add('TestMoreBytesPlease')
      end
    end
    it 'yields the request block with raw data, as soon as it appears' do
      callback = double(:callback)
      expect(callback).to receive(:a).with('TestBytes').ordered
      expect(callback).to receive(:b).with('MoreTestBytes').ordered
      expect(callback).to receive(:c).with('EvenMore').ordered

      # Add request first, provide enough bytes
      subject.request(9, &callback.method(:a))
      subject.add('TestBytesMore')

      # Add request first, do not provide enough bytes initially
      subject.request(13, &callback.method(:b))
      subject.add('Test')
      subject.add('Bytes')

      # Add request after data
      subject.add('EvenMore')
      subject.request(8, &callback.method(:c))
    end
  end

  describe '#packed_request' do
    it 'yields the request block with unpacked data, as soon as it appears' do
      callback = double(:callback)
      expect(callback).to receive(:a).with([2001]).ordered
      expect(callback).to receive(:b).with(['MoreTestBytes']).ordered
      expect(callback).to receive(:c).with([12, 34, 56]).ordered

      # Add request first, provide enough bytes
      subject.packed_request(4, 'N', &callback.method(:a))
      subject.add([2001].pack('N') + 'More')

      # Add request first, do not provide enough bytes initially
      subject.packed_request(13, 'a13', &callback.method(:b))
      subject.add('Test')
      subject.add('Bytes')

      # Add request after data
      subject.add([12, 34, 56].pack('nnn'))
      subject.packed_request(6, 'nnn', &callback.method(:c))
    end
  end
end
