require_relative '../models/playlist'
require_relative '../models/item'

describe Bra::Models::Playlist do
  let(:playlist) { Bra::Models::Playlist.new }
  let(:test1)    { Bra::Models::Item.new(:library, '1') }
  let(:test2)    { Bra::Models::Item.new(:library, '2') }
  let(:test3)    { Bra::Models::Item.new(:library, '3') }

  describe '#post_do' do
    context 'with a Hash mapping from an unoccupied index to an Item' do
      it 'adds the item at that index' do
        playlist.post_do({ 3 => test1 })
        expect(playlist.children).to eq([nil, nil, nil, test1])

        playlist.post_do({ 0 => test2 })
        expect(playlist.children).to eq([test2, nil, nil, test1])
      end
    end
    context 'with a Hash mapping from an occupied index to an Item' do
      it 'replaces the item at that index' do
        playlist.post_do({ 3 => test1 })
        expect(playlist.children).to eq([nil, nil, nil, test1])

        playlist.post_do({ 3 => test2 })
        expect(playlist.children).to eq([nil, nil, nil, test2])
      end
    end
    context 'with an Item' do
      it 'adds the item to the end of the playlist' do
        playlist.post_do(test1)
        expect(playlist.children).to eq([test1])

        playlist.post_do({ 2 => test2 })
        expect(playlist.children).to eq([test1, nil, test2])

        playlist.post_do(test3)
        expect(playlist.children).to eq([test1, nil, test2, test3])
      end
    end
  end

  describe '#delete_do' do
    context 'with Items enqueued' do
      it 'clears the playlist' do
        test1.move_to(playlist, 0)
        test2.move_to(playlist, 1)
        test3.move_to(playlist, 2)

        expect(playlist.children).to eq([test1, test2, test3])
        playlist.delete_do
        p(playlist.children)
        expect(playlist.children).to be_empty
        expect(test1.parent).to be_nil
        expect(test2.parent).to be_nil
        expect(test3.parent).to be_nil
      end
    end
  end
end
