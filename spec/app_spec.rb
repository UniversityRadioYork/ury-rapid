require 'bra/app'
require 'bra/model'

describe Bra::App do
  subject { Bra::App.new([service], [server], service_view, reactor) }

  let(:service)      { double(:service) }
  let(:server)      { double(:server) }
  let(:service_view) { double(:service_view) }
  let(:reactor)     { double(:reactor) }

  describe '#run' do
    before(:each) do
      allow(service).to receive(:run)
      allow(server).to receive(:run)
      allow(reactor).to receive(:run).and_yield

      # Logging messages go through the service view, which has access to the
      # logger.  This is normal.
      allow(service_view).to receive(:log)
    end

    it 'calls #run on the reactor' do
      expect(reactor).to receive(:run).once.with(no_args)
      subject.run
    end

    it 'calls #run on the server' do
      expect(server).to receive(:run).once.with(no_args)
      subject.run
    end

    it 'calls #run on the service' do
      expect(service).to receive(:run).once.with(no_args)
      subject.run
    end
  end
end
