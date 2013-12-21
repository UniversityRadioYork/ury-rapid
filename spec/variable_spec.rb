require 'spec_helper'

require 'bra/models/variable'

TestVariable = Class.new(Bra::Models::Variable)

describe Bra::Models::Variable do
  subject { v_class.new(initial_value, validator, target) }
  let(:v_class) { Bra::Models::Variable }
  let(:initial_value) { double(:initial_value) }
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

  describe '#handler_target' do
    context 'when the subject is not a subclass' do
      context 'and and handler_target is nil' do
        it 'returns the relative, underscored class name as a symbol' do
          expect(subject.handler_target).to eq(:variable)
        end
      end
      context 'and the handler_target is defined' do
        let(:target) { :arsenic_catnip }
        it 'returns that handler_target' do
          expect(subject.handler_target).to eq(:arsenic_catnip)
        end
      end
    end
    context 'when the subject is a subclass' do
      let(:v_class) { TestVariable }
      context 'and and handler_target is nil' do
        it 'returns the relative, underscored class name as a symbol' do
          expect(subject.handler_target).to eq(:test_variable)
        end
      end
      context 'and the handler_target is defined' do
        let(:target) { :noel_edmonds }
        it 'returns that handler_target' do
          expect(subject.handler_target).to eq(:noel_edmonds)
        end
      end
    end
  end
end
