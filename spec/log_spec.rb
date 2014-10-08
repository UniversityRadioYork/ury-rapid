require 'ury_rapid/model/log'

describe Rapid::Model::Log do
  let(:logger) { double(:logger) }
  subject { Rapid::Model::Log.new(logger) }

  describe '#insert' do
    context 'when the ID is a valid log level' do
      it 'calls the corresponding method on the logger with the payload' do
        expect(logger).to receive(:debug).ordered.with('Hey')
        expect(logger).to receive(:info).ordered.with('there')
        expect(logger).to receive(:warn).ordered.with('officer,')
        expect(logger).to receive(:error).ordered.with('how are')
        expect(logger).to receive(:fatal).ordered.with('you doing?')

        subject.insert(:debug, 'Hey')
        subject.insert(:info, 'there')
        subject.insert(:warn, 'officer,')
        subject.insert(:error, 'how are')
        subject.insert(:fatal, 'you doing?')
      end
    end

    context 'when the ID is not a valid log level' do
      specify { expect { subject.insert(:nope, 'Nope') }.to raise_error }
    end
  end
end
