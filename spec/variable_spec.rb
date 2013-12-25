require 'spec_helper'

require 'bra/model/variable'

describe Bra::Model::Variable do
  subject { Bra::Model::Variable.new(initial_value, validator, target) }
  let(:initial_value) { 'sample' }
  let(:validator) { double(:validator) }
  let(:target) { nil }

  describe '#method_missing' do
    context 'when given a valid value' do
      it 'delegates missing methods to that value' do
        expect(initial_value).to receive(:foo).with(no_args).and_return(343)
        expect(subject.foo).to eq(343)
      end
    end
  end
  describe '#driver_put' do
    let(:channel) { double(:channel) }

    before(:each) do
      subject.register_update_channel(channel)
    end

    context 'when the Variable has a validator' do
    end
    context 'when the Variable has no validator' do
      let(:validator) { nil }

      context 'when the current value is the same as the proposed value' do
        it 'does not notify an update' do
          subject.driver_put(initial_value)
        end

        it 'does not change the value object' do
          expect(subject.value).to be(initial_value)
          subject.driver_put(initial_value)
          expect(subject.value).to be(initial_value)
        end

        it 'does not mutate the value' do
          old_value = subject.value.clone
          subject.driver_put(initial_value)
          expect(subject.value).to eq(old_value)
        end
      end
      context 'when the current value differs from the proposed value' do
        before(:each) { allow(channel).to receive(:notify_update) }
        let(:new_value) { :ghostbusters }

        it 'notifies the updates channel of the new value' do
          expect(channel).to receive(:notify_update).once.with(subject)

          subject.driver_put(new_value)
        end

        it 'changes the value to the new value' do
          expect(subject.value).to eq(initial_value)
          subject.driver_put(new_value)
          expect(subject.value).to eq(new_value)
        end
      end
    end

    context 'when the Variable has a validator' do
      let(:requested_value) { 300 }

      before(:each) do
        allow(validator).to receive(:call).and_return(validated_value)
      end

      context 'when the current value is the same as the validator output' do
        let(:validated_value) { initial_value }

        it 'does not notify an update' do
          subject.driver_put(requested_value)
        end

        it 'calls the validator with the requested value' do
          expect(validator).to receive(:call).once.with(requested_value)

          subject.driver_put(requested_value)
        end

        it 'does not change the value object' do
          expect(subject.value).to be(initial_value)
          subject.driver_put(requested_value)
          expect(subject.value).to be(initial_value)
        end

        it 'does not mutate the value' do
          old_value = subject.value.clone
          subject.driver_put(requested_value)
          expect(subject.value).to eq(old_value)
        end
      end
      context 'when the current value differs from the validator output' do
        let(:validated_value) { :ghostbusters }

        before(:each) { allow(channel).to receive(:notify_update) }

        it 'notifies the updates channel of the new value' do
          expect(channel).to receive(:notify_update).once.with(subject)
          subject.driver_put(initial_value)
        end

        it 'changes the value to the new value' do
          expect(subject.value).to eq(initial_value)
          subject.driver_put(initial_value)
          expect(subject.value).to eq(validated_value)
        end
      end
    end
  end

  describe '#driver_delete' do
    context 'when the value has not changed' do
      it 'calls #driver_put with the initial value' do
        allow(subject).to receive(:driver_put)
        expect(subject).to receive(:driver_put).once.with(initial_value)

        subject.driver_delete
      end
    end
    context 'when the value has changed' do
      let(:validator) { nil }

      it 'calls #driver_put with the initial value' do
        allow(subject).to receive(:driver_put)
        expect(subject).to receive(:driver_put).once.with(initial_value)

        subject.driver_put(:snozzballs)
        subject.driver_delete
      end
    end
  end

  describe '#handler_target' do
    context 'when the handler_target is nil' do
      it 'returns the relative, underscored class name as a symbol' do
        expect(subject.handler_target).to eq(:variable)
      end
    end
    context 'when the handler_target is defined' do
      let(:target) { :noel_edmonds }
      it 'returns that handler_target' do
        expect(subject.handler_target).to eq(:noel_edmonds)
      end
    end
  end
end
