require 'ury-rapid/app'
require 'ury-rapid/model'

describe Rapid::App do
  subject { Rapid::App.new(module_set, service_view, reactor) }

  let(:module_set)   { double(:module) }
  let(:service_view) { double(:service_view) }
  let(:reactor)      { double(:reactor) }

  describe '#run' do
    before(:each) do
      allow(module_set).to receive(:run)
      allow(reactor).to receive(:run).and_yield

      # Logging messages go through the service view, which has access to the
      # logger.  This is normal.
      allow(service_view).to receive(:log)
    end

    it 'calls #run on the reactor' do
      subject.run
      expect(reactor).to have_received(:run).once.with(no_args)
    end

    it 'calls #run on the module set' do
      subject.run
      expect(module_set).to have_received(:run).once.with(no_args)
    end
  end
end
