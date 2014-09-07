require 'ury-rapid/app'
require 'ury-rapid/model'

describe Rapid::App do
  subject { Rapid::App.new(root_module, reactor) }

  let(:root_module) { double(:module) }
  let(:reactor)     { double(:reactor) }

  describe '#run' do
    before(:each) do
      allow(root_module).to receive(:run)
      allow(reactor).to receive(:run).and_yield

      # Logging messages go through the root module, which has access to the
      # logger.  This is normal.
      allow(root_module).to receive(:log)
    end

    it 'calls #run on the reactor' do
      subject.run
      expect(reactor).to have_received(:run).once.with(no_args)
    end

    it 'calls #run on the root module' do
      subject.run
      expect(root_module).to have_received(:run).once.with(no_args)
    end
  end
end
