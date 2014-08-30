require 'ury-rapid/model/log'

describe Rapid::Model::Log do
  let(:logger) { double(:logger) }
  subject { Rapid::Model::Log.new(logger) }

  describe '#service_post' do
    context 'when the ID is a valid log level' do
      it 'calls the corresponding method on the logger with the payload' do
        expect(logger).to receive(:debug).ordered.with('Hey')
        expect(logger).to receive(:info).ordered.with('there')
        expect(logger).to receive(:warn).ordered.with('officer,')
        expect(logger).to receive(:error).ordered.with('how are')
        expect(logger).to receive(:fatal).ordered.with('you doing?')

        subject.service_post(:debug, 'Hey')
        subject.service_post(:info, 'there')
        subject.service_post(:warn, 'officer,')
        subject.service_post(:error, 'how are')
        subject.service_post(:fatal, 'you doing?')
      end
    end

    context 'when the ID is not a valid log level' do
      specify { expect { subject.service_post(:nope, 'Nope') }.to raise_error }
    end
  end
end
