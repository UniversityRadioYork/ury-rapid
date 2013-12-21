require 'spec_helper'

require 'bra/common/exceptions'
require 'bra/common/types'

describe Bra::Common::Types::Validators do
  describe '#validate_symbol' do
    let(:symbols) { %i{winner taco} }
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
        expect { subject.validate_symbol(:loser, symbols)}.to raise_error(
          Bra::Common::Exceptions::InvalidPayload
        )
      end
    end
  end
end
