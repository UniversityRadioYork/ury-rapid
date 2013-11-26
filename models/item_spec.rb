require_relative 'item'
require_relative 'composite'

describe Bra::Models::Item do
  let(:item) { Bra::Models::Item.new(:library, 'Brown Girl In The Ring') }
  # Brown girl in the ring, tra la la la la
  # There's a brown girl in the ring, tra la la la la la
  # Brown girl in the ring, tra la la la la
  # She looks like a sugar in a plum, plum plum!
  describe '#flat' do
    it 'flattens the Item into a hash representation' do
      expect(item.flat).to eq(
        { name: 'Brown Girl In The Ring', type: :library }
      )
    end
  end
  describe '#name' do
    it 'retrieves the name of the Item' do
      expect(item.name).to eq('Brown Girl In The Ring')
    end
  end
  describe '#type' do
    it 'retrieves the type of the Item' do
      expect(item.type).to eq(:library)
    end
  end
  describe '#set_from_hash' do
    context 'given a valid Hash' do
      it 'sets the contents of the Item to those in the Hash' do
        item.set_from_hash({ name: 'URY Whisper (Dry)', type: :file })
        expect(item.name).to eq('URY Whisper (Dry)')
        expect(item.type).to eq(:file)
      end
    end
  end
  describe '#set_from_item' do
    context 'given a valid Item' do
      it 'sets the contents of the Item to those in the other Item' do
        new_item = Bra::Models::Item.new(:file, 'URY 1')
        item.set_from_item(new_item)
        expect(item.name).to eq('URY 1')
        expect(item.type).to eq(:file)
      end
    end
  end
  describe '#delete_do' do
    context 'when the Item is in a parent object' do
      it 'removes the Item from that object' do
        lmo = Bra::Models::ListModelObject.new
        item.move_to(lmo, 0)
        expect(lmo.children).to eq([item])
        item.delete_do
        expect(lmo.children).to eq([])
      end
    end
  end

  # TODO(mattbw): Add artists etc. if drivers ever support them?
end
