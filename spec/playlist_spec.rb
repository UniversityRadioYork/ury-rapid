require 'spec_helper.rb'

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
  end

  def ignore_channel
    allow(channel).to receive(:push)
  end

  def ignore_handler
    allow(handler).to receive(:item_handler)
  end

  describe '#driver_post' do
    context 'when the index is valid' do
      context 'and the Item is not in the Playlist' do
        it 'registers the playlist updates channel with the Item' do
          ignore_handler

          expect(channel).to receive(:push).with([test1, test1.flat]).ordered
          expect(channel).to receive(:push).with([test2, test2.flat]).ordered
          expect(channel).to receive(:push).with([test3, test3.flat]).ordered

          subject.driver_post(0, test1)
          subject.driver_post(1, test2)
          subject.driver_post(0, test3)
        end
        it 'registers the playlist item handler with the Item' do
          ignore_channel

          expect(handler).to receive(:item_handler).with(test1).ordered
          expect(handler).to receive(:item_handler).with(test2).ordered
          expect(handler).to receive(:item_handler).with(test3).ordered

          subject.driver_post(0, test1)
          subject.driver_post(1, test2)
          subject.driver_post(0, test3)
        end
        it 'adds the Item to the Playlist at the requested index' do
          ignore_channel
          ignore_handler

          subject.driver_post(0, test1)
          expect(subject.children).to eq([test1])

          subject.driver_post(1, test2)
          expect(subject.children).to eq([test1, test2])

          # Should insert at 0 and move the other two
          subject.driver_post(0, test3)
          expect(subject.children).to eq([test3, test1, test2])
        end
        it 'sets the parent of the Item to the Playlist' do
          ignore_channel
          ignore_handler

          expect(test1.parent).to be_nil
          subject.driver_post(0, test1)
          expect(test1.parent).to eq(subject)
        end
      end

      context 'and the Item is already in the Playlist' do
        it 'moves the Item to the new Index' do
          ignore_channel
          ignore_handler

          subject.driver_post(0, test1)
          subject.driver_post(1, test2)
          subject.driver_post(2, test3)
          expect(subject.children).to eq([test1, test2, test3])

          subject.driver_post(2, test1)
          expect(subject.children).to eq([test2, test3, test1])

          subject.driver_post(0, test3)
          expect(subject.children).to eq([test3, test2, test1])
        end
        it 'keeps the parent as the Playlist' do
          ignore_channel
          ignore_handler

          expect(test1.parent).to be_nil
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
        test1.move_to(subject, 0).register_update_channel(channel)
        test2.move_to(subject, 1).register_update_channel(channel)
        test3.move_to(subject, 2).register_update_channel(channel)
      end

      it 'clears the Playlist' do
        ignore_channel

        expect(subject.children).to eq([test1, test2, test3])
        subject.driver_delete
        expect(subject.children).to be_empty
      end

      it 'sets each Item to have no parent' do
        ignore_channel

        expect(test1.parent).to eq(subject)
        expect(test2.parent).to eq(subject)
        expect(test3.parent).to eq(subject)

        subject.driver_delete

        expect(test1.parent).to be_nil
        expect(test2.parent).to be_nil
        expect(test3.parent).to be_nil
      end

      it 'announces each item deletion' do
        expect(channel).to receive(:push).with([test1, nil]).ordered
        expect(channel).to receive(:push).with([test2, nil]).ordered
        expect(channel).to receive(:push).with([test3, nil]).ordered

        subject.driver_delete
      end
    end
  end
end
