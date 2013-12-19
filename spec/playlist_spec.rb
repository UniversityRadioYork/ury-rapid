require 'bra/models/playlist'
require 'bra/models/item'

describe Bra::Models::Playlist do
  let(:playlist) { Bra::Models::Playlist.new }
  let(:test1)    { Bra::Models::Item.new(:library, '1', nil, nil) }
  let(:test2)    { Bra::Models::Item.new(:library, '2', nil, nil) }
  let(:test3)    { Bra::Models::Item.new(:library, '3', nil, nil) }

  describe '#driver_post' do
    context 'with a valid index and an Item' do
      it 'inserts, registers handler and channel, and notifies the channel' do
        handler = double(:handler)
        channel = double(:channel)

        # As each item is POSTed, it'll ask for a handler then notify the
        # updates channel.
        handler.should_receive(:item_handler).with(test1).ordered
        channel.should_receive(:push).with([test1, test1.flat]).ordered
        handler.should_receive(:item_handler).with(test2).ordered
        channel.should_receive(:push).with([test2, test2.flat]).ordered
        handler.should_receive(:item_handler).with(test3).ordered
        channel.should_receive(:push).with([test3, test3.flat]).ordered

        playlist.register_handler(handler)
        playlist.register_update_channel(channel)

        playlist.driver_post(0, test1)
        expect(playlist.children).to eq([test1])

        playlist.driver_post(1, test2)
        expect(playlist.children).to eq([test1, test2])

        # Should insert at 0 and move the other two
        playlist.driver_post(0, test3)
        expect(playlist.children).to eq([test3, test1, test2])
      end
    end
  end

  describe '#driver_delete' do
    context 'with Items enqueued' do
      it 'clears the playlist and announces each item deletion' do
        channel = double(:channel)
        channel.should_receive(:push).with([test1, nil]).ordered
        channel.should_receive(:push).with([test2, nil]).ordered
        channel.should_receive(:push).with([test3, nil]).ordered

        test1.move_to(playlist, 0).register_update_channel(channel)
        test2.move_to(playlist, 1).register_update_channel(channel)
        test3.move_to(playlist, 2).register_update_channel(channel)

        expect(playlist.children).to eq([test1, test2, test3])
        playlist.driver_delete
        p(playlist.children)
        expect(playlist.children).to be_empty
        expect(test1.parent).to be_nil
        expect(test2.parent).to be_nil
        expect(test3.parent).to be_nil
      end
    end
  end
end
