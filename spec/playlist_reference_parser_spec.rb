require 'bra/driver_common/requests/playlist_reference_parser'

# Mock implementation of PlaylistReferenceParser.
class MockPrp < Bra::DriverCommon::Requests::PlaylistReferenceParser 
  def local_playlist
    :local_id
  end
end

describe MockPrp do
  describe '#local_playlist?' do
    context 'when the given playlist equals #local playlist' do
      specify { expect(subject.local_playlist(:local_id)).to be_true }
    end

    context 'when the given playlist does not equal #local playlist' do
      specify { expect(subject.local_playlist(:foreign_id)).to be_false }
    end
  end

  describe '#parse_playlist_reference_url' do
  end

  describe '#parse_playlist_reference_hash' do
  end
end
