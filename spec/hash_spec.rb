require 'spec_helper'

require 'ury-rapid/common/hash'

describe Hash do
  describe '.new_with_default_block' do
    context 'given a hash and a block' do
      it 'creates a new hash from the given hash and default block' do
        # We can't easily test this with the usual expect yield constructs, as
        # then we can't check to see if the default returns the hash properly.
        a = Hash.new_with_default_block(a: 22) { |h, k| [h, k] }
        expect(a[:a]).to eq(22)
        expect(a[:b]).to eq([a, :b])
      end
    end
  end
end
