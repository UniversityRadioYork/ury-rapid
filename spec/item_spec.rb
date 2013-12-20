require 'bra/models/item'
require 'bra/models/composite'

describe Bra::Models::Item do
  subject do
    Bra::Models::Item.new(type, name, origin, duration)
  end
  let(:type) { :library }
  let(:name) { 'Brown Girl In The Ring' }
  let(:origin) { 'playlist://0/0' }
  let(:duration) { 31415 }

  # Brown girl in the ring, tra la la la la
  # There's a brown girl in the ring, tra la la la la la
  # Brown girl in the ring, tra la la la la
  # She looks like a sugar in a plum, plum plum!
  describe '#flat' do
    it 'flattens the Item into a hash representation' do
      expect(subject.flat).to eq(
        { name: name,
          type: type,
          origin: origin,
          duration: duration
        }
      )
    end
  end
  describe '#name' do
    it 'retrieves the name of the Item' do
      expect(subject.name).to eq(name)
    end
  end
  describe '#type' do
    it 'retrieves the type of the Item' do
      expect(subject.type).to eq(type)
    end
  end
  describe '#driver_delete' do
    context 'when the Item is in a parent object' do
      let(:parent) { Bra::Models::ListModelObject.new }

      it 'removes the Item from that object' do
        channel = double(:channel)
        allow(channel).to receive(:push)
        subject.register_update_channel(channel)

        subject.move_to(parent, 0)
        expect(parent.children).to eq([subject])
        subject.driver_delete
        expect(parent.children).to eq([])
      end

      it 'notifies the channel' do
        # Ensure the update channel is notified of the deletion
        channel = double(:channel)
        channel.should_receive(:push).with([subject, nil]).once
        subject.register_update_channel(channel)

        subject.move_to(parent, 0)
        subject.driver_delete
      end
    end
  end

  # TODO(mattbw): Add artists etc. if drivers ever support them?
end
