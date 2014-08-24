require 'spec_helper'

require 'bra/common/exceptions'
require 'bra/common/types'

describe Bra::Common::Types::Validators do
  describe '#validate_volume' do
    context 'when the input is a float between 0.0 and 1.0' do
      it 'returns that value' do
        (0.0..1.0).step(0.1) do |n|
          expect(subject.validate_volume(n)).to eq(n)
        end
      end
    end
    context 'when the input is above 1.0' do
      it 'returns 1.0' do
        expect(subject.validate_volume(1.2)).to eq(1.0)
      end
    end
    context 'when the input is above 1.0' do
      it 'returns 0.0' do
        expect(subject.validate_volume(-0.2)).to eq(0.0)
      end
    end
  end

  describe '#validate_symbol' do
    let(:symbols) { %i(winner taco) }
    context 'when the input is a symbol in the range' do
      it 'returns the symbol' do
        expect(subject.validate_symbol(:winner, symbols)).to eq(:winner)
      end
    end
    context 'when the input can be converted to a symbol in the range' do
      it 'returns that symbol' do
        expect(subject.validate_symbol('winner', symbols)).to eq(:winner)
      end
    end
    context 'when the input cannot be a symbol in the range' do
      it 'fails with InvalidPayload' do
        expect { subject.validate_symbol(:loser, symbols) }.to raise_error(
          Bra::Common::Exceptions::InvalidPayload
        )
      end
    end
  end
end
