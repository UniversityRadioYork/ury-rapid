require_relative 'item'

describe Bra::Models::Item do
  before :each do
    @item = Bra::Models::Item.new(:library, 'Brown Girl In The Ring')
    # Brown girl in the ring, tra la la la la
    # There's a brown girl in the ring, tra la la la la la
    # Brown girl in the ring, tra la la la la
    # She looks like a sugar in a plum, plum plum!
  end
  describe '#flat' do
    it 'flattens the Item into a hash representation' do
      @item.flat.should eq({ name: 'Brown Girl In The Ring', type: :library })
    end
  end
  describe '#name' do
    it 'retrieves the name of the Item' do
      @item.name.should eq('Brown Girl In The Ring')
    end
  end
  describe '#type' do
    it 'retrieves the type of the Item' do
      @item.type.should eq(:library)
    end
  end
  describe '#set_from_hash' do
    context 'given a valid Hash' do
      it 'sets the contents of the Item to those in the Hash' do
        @item.set_from_hash({ name: 'URY Whisper (Dry)', type: :file })
        @item.name.should eq('URY Whisper (Dry)')
        @item.type.should eq(:file)
      end
    end
  end

  # TODO(mattbw): Add artists etc. if drivers ever support them?
end
