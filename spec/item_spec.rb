require 'spec_helper'

require 'bra/model/item'
require 'bra/model/composite'

describe Bra::Model::Item do
  subject { build(:item) }
  let(:attrs) { attributes_for(:item) }

  describe '#flat' do
    it 'flattens the Item into a hash representation' do
      expect(subject.flat).to eq(
        { name:     attrs[:name],
          type:     attrs[:type],
          origin:   attrs[:origin],
          duration: attrs[:duration]
        }
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
  describe '#driver_delete' do
    context 'when the Item is in a parent object' do
      let(:parent) { Bra::Model::Playlist.new }
      let(:channel) { double(:channel) }

      before(:each) do
        allow(channel).to receive(:notify_delete)
        subject.register_update_channel(channel)

        subject.move_to(parent, 0)
      end

      it 'removes the Item from that object' do
        expect(parent.children).to eq(0 => subject)
        subject.driver_delete
        expect(parent.children).to eq({})
      end

      it 'notifies the channel' do
        expect(channel).to receive(:notify_delete).with(subject).once

        subject.driver_delete
      end

      it 'sets the ID of the Item to nil' do
        expect(subject.id).to eq(0)
        subject.driver_delete
        expect(subject.id).to be_nil
      end
    end
  end

  describe '#driver_put' do
    let(:parent) { Bra::Model::Playlist.new }

    it 'calls #driver_post on the parent with its current ID' do
      payload = double(:payload)
      subject.move_to(parent, 0)

      allow(parent).to receive(:driver_post)
      expect(parent).to receive(:driver_post).with(0, payload)

      subject.driver_put(payload)
    end
  end

  # TODO(mattbw): Add artists etc. if drivers ever support them?
end
