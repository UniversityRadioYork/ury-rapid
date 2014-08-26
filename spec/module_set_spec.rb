require 'bra/launcher'

describe Bra::ModuleSet do
  class DummyModule
  end

  describe '#start' do
    subject { Bra::ModuleSet.new }

    before(:each) do
      subject.configure(:module1, DummyModule) do
      end
    end

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
