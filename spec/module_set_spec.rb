require 'ury-rapid/modules/set'

describe Rapid::Modules::Set do
  subject { Rapid::Modules::Set.new }

  describe '#enable_all' do
    context 'when no modules are configured' do
      # Enabling 0 modules should be a no-op.
      specify do
        set = build(:empty_module_set)

        expect { set.enable_all }.not_to raise_error
      end

      it 'adds no modules to #enabled' do
        set = build(:empty_module_set)

        expect { set.enable_all }.not_to change { set.enabled }
        expect(set.enabled).to be_empty
      end

      it 'removes no modules from #disabled' do
        set = build(:empty_module_set)

        expect { set.enable_all }.not_to change { set.disabled }
      end
    end

    context 'when some modules are configured' do
      it 'adds all modules to #enabled' do
        set = build(:non_empty_module_set, modules: %i(foo bar))

        expect { set.enable_all }.to change { set.enabled }.from([])
        expect(set.enabled).to contain_exactly(:foo, :bar)
      end

      it 'empties #disabled' do
        set = build(:non_empty_module_set, modules: %i(foo bar))

        expect(set.disabled).to contain_exactly(:foo, :bar)
        expect { set.enable_all }.to change { set.disabled }.to([])
      end
    end
  end

  describe '#enable' do
    context 'when the module is not configured' do
      specify do
        set = build(:non_empty_module_set, modules: %i(foo bar))

        expect { set.enable(:baz) }.to raise_error
      end
    end

    context 'when the module is configured' do
      specify do
        set = build(:non_empty_module_set, modules: %i(foo bar))

        expect { set.enable(:foo) }.not_to raise_error
        expect { set.enable(:bar) }.not_to raise_error
      end

      it 'adds the module to #enabled' do
        set = build(:non_empty_module_set, modules: %i(foo bar))

        expect { set.enable(:foo) }.to change { set.enabled }.from([])
        expect(set.enabled).to include(:foo)
      end

      it 'removes the module from #disabled' do
        set = build(:non_empty_module_set, modules: %i(foo bar))

        expect(set.disabled).to include(:foo)
        expect { set.enable(:foo) }.to change { set.disabled }
        expect(set.disabled).not_to include(:foo)
      end
    end

    context 'when the module has already been enabled' do
      specify do
        set = build(:non_empty_module_set,
                    modules: %i(foo bar),
                    enabled: %i(foo))

        expect { set.enable(:foo) }.not_to change { set.enabled }.from([:foo])
      end

      specify do
        set = build(:non_empty_module_set,
                    modules: %i(foo bar),
                    enabled: %i(foo))

        expect { set.enable(:foo) }.not_to change { set.disabled }.from([:bar])
      end
    end
  end

  describe '#start' do
    context 'when the module is not configured' do
      specify do
        set = build(:non_empty_module_set, modules: %i(foo bar))

        expect { set.start(:baz) }.to raise_error
      end
    end

    context 'when the module is configured' do
      class FakeModule
        def new(*_args)
        end

        def run
        end
      end

      it 'proceeds without error' do
        set = build(:non_empty_module_set,
                    modules: %i(foo bar),
                    enabled: %i(foo))

        expect { set.start(:foo) }.not_to raise_error
        expect { set.start(:bar) }.not_to raise_error
      end

      it 'instantiates the DummyModule' do
        md = double(:module)
        allow(md).to receive(:run)

        allow(FakeModule).to receive(:new).and_return(md)

        build(:non_empty_module_set,
              modules: [:foo],
              module_class: FakeModule).start(:foo)
        expect(FakeModule).to have_received(:new).once
      end

      it 'calls #build on the model builder with a module name and instance' do
        mb = double(:model_builder)
        allow(mb).to receive(:build)

        build(:non_empty_module_set,
              modules: [:foo],
              module_class: FakeModule,
              model_builder: mb).start(:foo)
        expect(mb).to have_received(:build)
                  .once.with(:foo, a_kind_of(FakeModule))
      end
    end
  end
end
