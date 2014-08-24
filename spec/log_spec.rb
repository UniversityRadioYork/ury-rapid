require 'bra/model/log'

describe Bra::Model::Log do
  let(:logger) { double(:logger) }
  subject { Bra::Model::Log.new(logger) }

  describe '#driver_post' do
    context 'when the ID is a valid log level' do
      it 'calls the corresponding method on the logger with the payload' do
        expect(logger).to receive(:debug).ordered.with('Hey')
        expect(logger).to receive(:info).ordered.with('there')
        expect(logger).to receive(:warn).ordered.with('officer,')
        expect(logger).to receive(:error).ordered.with('how are')
        expect(logger).to receive(:fatal).ordered.with('you doing?')

        subject.driver_post(:debug, 'Hey')
        subject.driver_post(:info, 'there')
        subject.driver_post(:warn, 'officer,')
        subject.driver_post(:error, 'how are')
        subject.driver_post(:fatal, 'you doing?')
      end
    end

    context 'when the ID is not a valid log level' do
      specify { expect { subject.driver_post(:nope, 'No way') }.to raise_error }
    end
  end
end
