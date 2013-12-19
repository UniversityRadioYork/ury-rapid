require_relative '../models/item'
require_relative '../models/composite'

describe Bra::Models::Item do
  let(:item) do
    Bra::Models::Item.new(
      :library,
      'Brown Girl In The Ring',
      'playlist://0/0',
      31415
    )
  end
  # Brown girl in the ring, tra la la la la
  # There's a brown girl in the ring, tra la la la la la
  # Brown girl in the ring, tra la la la la
  # She looks like a sugar in a plum, plum plum!
  describe '#flat' do
    it 'flattens the Item into a hash representation' do
      expect(item.flat).to eq(
        { name: 'Brown Girl In The Ring',
          type: :library,
          origin: 'playlist://0/0',
          duration: 31415
        }
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
  describe '#driver_delete' do
    context 'when the Item is in a parent object' do
      it 'removes the Item from that object, and notifies the channel' do
        # Ensure the update channel is notified of the deletion
        channel = double(:channel)
        channel.should_receive(:push).with([item, nil])
        item.register_update_channel(channel)

        lmo = Bra::Models::ListModelObject.new
        item.move_to(lmo, 0)
        expect(lmo.children).to eq([item])
        item.driver_delete
        expect(lmo.children).to eq([])
      end
    end
  end

  # TODO(mattbw): Add artists etc. if drivers ever support them?
end
