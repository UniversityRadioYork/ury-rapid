require 'bra/driver_common/requests/playlist_reference_parser'

# Mock implementation of PlaylistReferenceParser.
class MockPrp < Bra::DriverCommon::Requests::PlaylistReferenceParser 
  def local_playlist_id
    :local_id
  end
end

describe MockPrp do
  describe '#local_playlist?' do
    context 'when the given playlist equals #local playlist_id' do
      specify { expect(subject.local_playlist(:local_id)).to be_true }
    end

    context 'when the given playlist does not equal #local playlist' do
      specify { expect(subject.local_playlist(:foreign_id)).to be_false }
    end
  end

  describe '#parse_playlist_reference_url' do
    context 'when given a string representing a natural' do
      it 'returns an Array containing #local_playlist_id and the natural' do
        [0, 1, 10, 100, 23456].each do |example|
          expect(
            subject.parse_playlist_reference_url(example.to_s)
          ).to eq([local_playlist_id, example])
        end
      end
    end

    context 'when given a string with a slash followed by a natural' do
      it 'returns an Array of the prefix as a Symbol and the natural' do
        [0, 1, 10, 100, 23456].each do |number|
          %w{flibble dibble purple doggie doo}.each do |playlist|
            expect(
              subject.parse_playlist_reference_url("#{playlist}/#{number}")
            ).to eq([playlist.to_sym, example])
          end
        end
      end
    end

    context 'when given a string with a slash followed by a non-natural' do
      specify do
        expect { subject.parse_playlist_reference_url("squir/tle") }.to(
          raise_error
        )
      end
    end
  end

  describe '#parse_playlist_reference_hash' do
  end
end
