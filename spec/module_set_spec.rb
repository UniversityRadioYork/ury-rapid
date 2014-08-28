require 'ury-rapid/common/module_set'

describe Rapid::Common::ModuleSet do
  subject { Rapid::Common::ModuleSet.new }

  class DummyModule
  end

  before(:each) do
    modules.each { |m| subject.configure(m, DummyModule) {} }
  end

  let(:modules) { %i(module1 module3 module5 module7) }

  describe '#enable_all' do
    context 'when no modules are configured' do
      let(:modules) { [] }

      # Enabling 0 modules should be a no-op.
      specify { expect { subject.enable_all.to_not raise_error } }

      it 'adds no modules to #enabled' do
        expect { subject.enable_all }.to_not change { subject.enabled }
        expect(subject.enabled).to be_empty
      end
    end

    context 'when some modules are configured' do
      specify { expect { subject.enable_all.to_not raise_error } }

      it 'adds all modules to #enabled' do
        expect { subject.enable_all }.to change { subject.enabled }
                                     .from([])
        expect(subject.enabled).to contain_exactly(*modules)
      end
    end
  end

  describe '#enable' do
    context 'when the module is not configured' do
      specify { expect { subject.enable(:module2).to raise_error } }
    end

    context 'when the module is configured' do
      specify { expect { subject.enable(:module1).to_not raise_error } }

      it 'adds the module to #enabled' do
        expect { subject.enable(:module1) }.to change { subject.enabled }
                                           .from([])
        expect(subject.enabled).to include(:module1)
      end
    end

    context 'when the module has already been enabled' do
      before(:each) { subject.enable(:module1) }

      it 'does not change #enabled' do
        expect { subject.enable(:module1) }.to_not change { subject.enabled }
      end
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
