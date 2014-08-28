require 'ury-rapid/app'
require 'ury-rapid/model'

describe Rapid::App do
  subject { Rapid::App.new(service_set, server_set, service_view, reactor) }

  let(:service_set)  { double(:service) }
  let(:server_set)   { double(:server) }
  let(:service_view) { double(:service_view) }
  let(:reactor)      { double(:reactor) }

  describe '#run' do
    before(:each) do
      allow(service_set).to receive(:start_enabled)
      allow(server_set).to receive(:start_enabled)
      allow(reactor).to receive(:run).and_yield

      # Logging messages go through the service view, which has access to the
      # logger.  This is normal.
      allow(service_view).to receive(:log)
    end

    it 'calls #run on the reactor' do
      subject.run
      expect(reactor).to have_received(:run).once.with(no_args)
    end

    it 'calls #start_enabled on the server set' do
      subject.run
      expect(server_set).to have_received(:start_enabled).once.with(no_args)
    end

    it 'calls #start_enabled on the service set' do
      subject.run
      expect(service_set).to have_received(:start_enabled).once.with(no_args)
    end
  end
end
