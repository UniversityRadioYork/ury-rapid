require 'ury_rapid/services/set'

describe Rapid::Services::Set do
  subject { Rapid::Services::Set.new }

  describe '#enable_all' do
    context 'when no services are configured' do
      # Enabling 0 services should be a no-op.
      specify do
        set = build(:empty_service_set)

        expect { set.enable_all }.not_to raise_error
      end

      it 'adds no services to #enabled' do
        set = build(:empty_service_set)

        expect { set.enable_all }.not_to change { set.enabled }
        expect(set.enabled).to be_empty
      end

      it 'removes no services from #disabled' do
        set = build(:empty_service_set)

        expect { set.enable_all }.not_to change { set.disabled }
      end
    end

    context 'when some services are configured' do
      it 'adds all services to #enabled' do
        set = build(:non_empty_service_set, services: %i(foo bar))

        expect { set.enable_all }.to change { set.enabled }.from([])
        expect(set.enabled).to contain_exactly(:foo, :bar)
      end

      it 'empties #disabled' do
        set = build(:non_empty_service_set, services: %i(foo bar))

        expect(set.disabled).to contain_exactly(:foo, :bar)
        expect { set.enable_all }.to change { set.disabled }.to([])
      end
    end
  end

  describe '#enable' do
    context 'when the service is not configured' do
      specify do
        set = build(:non_empty_service_set, services: %i(foo bar))

        expect { set.enable(:baz) }.to raise_error
      end
    end

    context 'when the service is configured' do
      specify do
        set = build(:non_empty_service_set, services: %i(foo bar))

        expect { set.enable(:foo) }.not_to raise_error
        expect { set.enable(:bar) }.not_to raise_error
      end

      it 'adds the service to #enabled' do
        set = build(:non_empty_service_set, services: %i(foo bar))

        expect { set.enable(:foo) }.to change { set.enabled }.from([])
        expect(set.enabled).to include(:foo)
      end

      it 'removes the service from #disabled' do
        set = build(:non_empty_service_set, services: %i(foo bar))

        expect(set.disabled).to include(:foo)
        expect { set.enable(:foo) }.to change { set.disabled }
        expect(set.disabled).not_to include(:foo)
      end
    end

    context 'when the service has already been enabled' do
      specify do
        set = build(:non_empty_service_set,
                    services: %i(foo bar),
                    enabled: %i(foo))

        expect { set.enable(:foo) }.not_to change { set.enabled }.from([:foo])
      end

      specify do
        set = build(:non_empty_service_set,
                    services: %i(foo bar),
                    enabled: %i(foo))

        expect { set.enable(:foo) }.not_to change { set.disabled }.from([:bar])
      end
    end
  end

  describe '#start' do
    context 'when the service is not configured' do
      specify do
        set = build(:non_empty_service_set, services: %i(foo bar))

        expect { set.start(:baz) }.to raise_error
      end
    end

    context 'when the service is configured' do
      it 'proceeds without error' do
        set = build(:non_empty_service_set,
                    services: %i(foo bar),
                    enabled: %i(foo))

        expect { set.start(:foo) }.not_to raise_error
        expect { set.start(:bar) }.not_to raise_error
      end

      # Note: DummyService is defined in spec/factories/service_set.rb.

      it 'instantiates the DummyService' do
        md = double(:service)
        allow(md).to receive(:run)

        allow(DummyService).to receive(:new).and_return(md)

        build(:non_empty_service_set,
              services: [:foo],
              service_class: DummyService).start(:foo)
        expect(DummyService).to have_received(:new).once
      end
    end
  end
end
