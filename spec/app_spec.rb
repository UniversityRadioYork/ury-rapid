require 'bra/app'
require 'bra/model'

describe Bra::App do
  subject { Bra::App.new(driver, model, server, reactor) }

  let(:driver)  { double(:driver) }
  let(:model)   { double(:model) }
  let(:server)  { double(:server) }
  let(:reactor) { double(:reactor) }

  describe '#run' do
    before(:each) do
      allow(driver).to receive(:run)
      allow(server).to receive(:run)
      allow(reactor).to receive(:run).and_yield()
    end

    it 'calls #run on the server with a ServerView' do
      expect(server).to receive(:run).once.with(
        an_instance_of(Bra::Model::ServerView)
      )
      subject.run
    end
    it 'calls #run on the driver with a DriverView' do
      expect(driver).to receive(:run).once.with(
        an_instance_of(Bra::Model::DriverView)
      )
      subject.run
    end
  end
end
