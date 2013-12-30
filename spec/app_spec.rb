require 'bra/app'
require 'bra/model'

describe Bra::App do
  subject { Bra::App.new(driver, driver_view, server, server_view, reactor) }

  let(:driver)      { double(:driver) }
  let(:driver_view) { double(:driver_view) }
  let(:server)      { double(:server) }
  let(:server_view) { double(:server_view) }
  let(:reactor)     { double(:reactor) }

  describe '#run' do
    before(:each) do
      allow(driver).to receive(:run)
      allow(server).to receive(:run)
      allow(reactor).to receive(:run).and_yield()
    end

    it 'calls #run on the reactor' do
      expect(reactor).to receive(:run).once.with(no_args)
      subject.run
    end

    it 'calls #run on the server with the server view' do
      expect(server).to receive(:run).once.with(server_view)
      subject.run
    end

    it 'calls #run on the driver with the driver view' do
      expect(driver).to receive(:run).once.with(driver_view)
      subject.run
    end
  end
end
