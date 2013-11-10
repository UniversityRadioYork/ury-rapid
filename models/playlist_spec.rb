require_relative 'channel'
require_relative 'item'

describe Bra::Models::Playlist do
  let(:playlist) { Bra::Models::Playlist.new }
  let(:test1)    { Bra::Models::Item.new(:library, '1') }
  let(:test2)    { Bra::Models::Item.new(:library, '2') }
  let(:test3)    { Bra::Models::Item.new(:library, '3') }

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
