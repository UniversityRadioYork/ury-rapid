require 'bra/app'
require 'bra/model'

describe Bra::App do
  subject { Bra::App.new([driver], [server], driver_view, reactor) }

  let(:driver)      { double(:driver) }
  let(:server)      { double(:server) }
  let(:driver_view) { double(:driver_view) }
  let(:reactor)     { double(:reactor) }

  describe '#run' do
    before(:each) do
      allow(driver).to receive(:run)
      allow(server).to receive(:run)
      allow(reactor).to receive(:run).and_yield()

      # Logging messages go through the driver view, which has access to the
      # logger.  This is normal.
      allow(driver_view).to receive(:log)
    end

    it 'calls #run on the reactor' do
      expect(reactor).to receive(:run).once.with(no_args)
      subject.run
    end

    it 'calls #run on the server' do
      expect(server).to receive(:run).once.with(no_args)
      subject.run
    end

    it 'calls #run on the driver' do
      expect(driver).to receive(:run).once.with(no_args)
      subject.run
    end
  end
end
