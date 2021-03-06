require 'spec_helper'

require 'ury_rapid/model/item'

describe Rapid::Model::Item do
  subject { build(:item) }
  let(:attrs) { attributes_for(:item) }

  describe '#flat' do
    it 'flattens the Item into a hash representation' do
      expect(subject.flat).to eq(
        name:     attrs[:name],
        type:     attrs[:type],
        origin:   attrs[:origin],
        duration: attrs[:duration]
      )
    end
  end

  describe '#name' do
    it 'retrieves the name of the Item' do
      expect(subject.name).to eq(attrs[:name])
    end
  end

  describe '#type' do
    it 'retrieves the type of the Item' do
      expect(subject.type).to eq(attrs[:type])
    end
  end

  describe '#kill' do
    context 'when the Item is in a parent object' do
      let(:parent) { build(:playlist) }
      let(:channel) { double(:channel) }

      before(:each) do
        allow(channel).to receive(:notify_delete)
        subject.register_update_channel(channel)

        subject.move_to(parent, 0)
      end

      it 'removes the Item from that object' do
        expect(parent.children).to eq(0 => subject)
        subject.kill
        expect(parent.children).to eq({})
      end

      it 'notifies the channel' do
        expect(channel).to receive(:notify_delete).with(subject).once

        subject.kill
      end

      it 'sets the ID of the Item to nil' do
        expect(subject.id).to eq(0)
        subject.kill
        expect(subject.id).to be_nil
      end
    end
  end

  describe '#replace' do
    let(:parent) { build(:playlist) }

    it 'calls #insert on the parent with its current ID' do
      payload = double(:payload)
      subject.move_to(parent, 0)

      allow(parent).to receive(:insert)
      expect(parent).to receive(:insert).with(0, payload)

      subject.replace(payload)
    end
  end

  # TODO(mattbw): Add artists etc. if services ever support them?
end
