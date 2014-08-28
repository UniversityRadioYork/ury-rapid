require 'ury-rapid/common/module_set'

describe Rapid::Common::ModuleSet do
  subject { Rapid::Common::ModuleSet.new }

  class DummyModule
    def run
    end
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

      it 'removes no modules from #disabled' do
        expect { subject.enable_all }.to_not change { subject.disabled }
      end
    end

    context 'when some modules are configured' do
      specify { expect { subject.enable_all.to_not raise_error } }

      it 'adds all modules to #enabled' do
        expect { subject.enable_all }.to change { subject.enabled }
                                     .from([])
        expect(subject.enabled).to contain_exactly(*modules)
      end

      it 'empties #disabled' do
        expect(subject.disabled).to contain_exactly(*modules)
        expect { subject.enable_all }.to change { subject.disabled }
                                     .to([])
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

      it 'removes the module from #disabled' do
        expect(subject.disabled).to include(:module1)
        expect { subject.enable(:module1) }.to change { subject.disabled }
        expect(subject.disabled).to_not include(:module1)
      end
    end

    context 'when the module has already been enabled' do
      before(:each) { subject.enable(:module1) }

      specify do
        expect { subject.enable(:module1) }.to_not change { subject.enabled }
      end

      specify do
        expect { subject.enable(:module1) }.to_not change { subject.disabled }
      end
    end
  end

  describe '#start' do
    context 'when the module is not configured' do
      specify { expect { subject.start(:module2).to raise_error } }
    end

    context 'when the module is configured' do
      before(:each) do
        dmnew = DummyModule.method(:new)
        allow(DummyModule).to receive(:new) do |*args|
          dmnew.call(*args)
        end
      end

      specify { expect { subject.start(:module1).to_not raise_error } }

      it 'instantiates the DummyModule' do
        subject.start(:module1)
        expect(DummyModule).to have_received(:new).once
      end
    end
  end
end
