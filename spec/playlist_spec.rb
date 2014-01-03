require 'spec_helper.rb'

require 'compo'
require 'bra/model/playlist'
require 'bra/model/item'

describe Bra::Model::Playlist do
  let(:test1)    { Bra::Model::Item.new(:library, '1', nil, nil) }
  let(:test2)    { Bra::Model::Item.new(:library, '2', nil, nil) }
  let(:test3)    { Bra::Model::Item.new(:library, '3', nil, nil) }

  let(:channel) { double(:channel) }
  let(:handler) { double(:handler) }

  before(:each) do
    subject.register_update_channel(channel)
    subject.register_handler(handler)

    test1.register_update_channel(channel)
    test2.register_update_channel(channel)
    test3.register_update_channel(channel)
  end

  describe '#driver_post' do
    before(:each) do
      allow(channel).to receive(:notify_update)
      allow(handler).to receive(:item_handler)
    end

    context 'when the index is valid' do
      context 'and the Item is not in the Playlist' do
        it 'announces the update to the updates channel' do
          expect(channel).to receive(:notify_update).with(test1).ordered
          expect(channel).to receive(:notify_update).with(test2).ordered
          expect(channel).to receive(:notify_update).with(test3).ordered

          subject.driver_post(0, test1)
          subject.driver_post(1, test2)
          subject.driver_post(0, test3)
        end
        it 'adds the Item to the Playlist at the requested index' do
          subject.driver_post(0, test1)
          expect(subject.children).to eq(0 => test1)

          subject.driver_post(1, test2)
          expect(subject.children).to eq(0 => test1, 1 => test2)

          # Should insert at 0 and move the other two
          subject.driver_post(0, test3)
          expect(subject.children).to eq(0 => test3, 1 => test1, 2 => test2)
        end
        it 'sets the parent of the Item to the Playlist' do
          expect(test1.parent).to be_a(Compo::Parentless)
          subject.driver_post(0, test1)
          expect(test1.parent).to eq(subject)
        end
      end

      context 'and the Item is already in the Playlist' do
        it 'moves the Item to the new Index' do
          subject.driver_post(0, test1)
          subject.driver_post(1, test2)
          subject.driver_post(2, test3)
          expect(subject.children).to eq(0 => test1, 1 => test2, 2 => test3)

          subject.driver_post(2, test1)
          expect(subject.children).to eq(0 => test2, 1 => test3, 2 => test1)

          subject.driver_post(0, test3)
          expect(subject.children).to eq(0 => test3, 1 => test2, 2 => test1)
        end
        it 'keeps the parent as the Playlist' do
          expect(test1.parent).to be_a(Compo::Parentless)
          subject.driver_post(0, test1)
          expect(test1.parent).to eq(subject)

          subject.driver_post(1, test2)
          subject.driver_post(1, test1)
          expect(test1.parent).to eq(subject)
        end
      end
    end
  end

  describe '#driver_delete' do
    context 'when no Items are enqueued' do
      it 'does nothing' do
        subject.driver_delete
      end
    end
    context 'when Items are enqueued' do
      before(:each) do
        allow(channel).to receive(:notify_delete)
        test1.move_to(subject, 0).register_update_channel(channel)
        test2.move_to(subject, 1).register_update_channel(channel)
        test3.move_to(subject, 2).register_update_channel(channel)
      end

      it 'clears the Playlist' do
        expect(subject.children).to eq(0 => test1, 1 => test2, 2 => test3)
        subject.driver_delete
        expect(subject.children).to be_empty
      end

      it 'sets each Item to have no parent' do
        expect(test1.parent).to eq(subject)
        expect(test2.parent).to eq(subject)
        expect(test3.parent).to eq(subject)

        subject.driver_delete

        expect(test1.parent).to be_a(Compo::Parentless)
        expect(test2.parent).to be_a(Compo::Parentless)
        expect(test3.parent).to be_a(Compo::Parentless)
      end

      it 'announces each item deletion' do
        expect(channel).to receive(:notify_delete).with(test1).ordered
        expect(channel).to receive(:notify_delete).with(test2).ordered
        expect(channel).to receive(:notify_delete).with(test3).ordered

        subject.driver_delete
      end
    end
  end
end
