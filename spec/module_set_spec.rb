require 'ury-rapid/common/module_set'

describe Rapid::Common::ModuleSet do
  subject { Rapid::Common::ModuleSet.new }

  class DummyModule
  end

  before(:each) do
    subject.configure(:module1, DummyModule) do
    end
  end

  describe "#enable" do
    context 'when the module is not configured' do
      specify { expect { subject.enable(:module2).to raise_error } }
    end

    context 'when the module is configured' do
      specify { expect { subject.enable(:module1).to_not raise_error } }
    end
  end

  describe '#start' do
    context 'when the module is not configured' do
      specify { expect { subject.start(:module2).to raise_error } }
    end

    context 'when the module is configured' do
      before(:each) do
        allow(DummyModule).to receive(:new)
      end

      specify { expect { subject.start(:module1).to_not raise_error } }

      it 'instantiates the DummyModule' do
        subject.start(:module1)
        expect(DummyModule).to have_received(:new).once
      end
    end
  end
end
