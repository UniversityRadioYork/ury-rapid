require 'bra/driver_common/requests/playlist_reference_parser'

# Mock implementation of PlaylistReferenceParser.
class MockPrp
  include Bra::DriverCommon::Requests::PlaylistReferenceParser

  def local_playlist_id
    :local_id
  end
end

describe MockPrp do
  describe '#local_playlist?' do
    context 'when the given playlist equals #local playlist_id' do
      specify { expect(subject.local_playlist?(:local_id)).to be_truthy }
    end

    context 'when the given playlist does not equal #local playlist' do
      specify { expect(subject.local_playlist?(:foreign_id)).to be_falsy }
    end
  end

  describe '#parse_playlist_reference_url' do
    context 'when given a String representing an Integer' do
      it 'returns an Array containing #local_playlist_id and the Integer' do
        [0, 1, 10, 100, 23_456].each do |example|
          expect(
            subject.parse_playlist_reference_url(example.to_s)
          ).to eq([subject.local_playlist_id, example])
        end
      end
    end

    context 'when given a String with a slash followed by an Integer' do
      context 'and the prefix represents an Integer' do
        it 'returns an Array of the prefix as an Integer and the Integer' do
          [0, 1, 10, 100, 23_456].each do |number|
            [2, 4, 6, 8, 999].each do |playlist|
              expect(
                subject.parse_playlist_reference_url("#{playlist}/#{number}")
              ).to eq([playlist, number])
            end
          end
        end
      end
      context 'and the prefix does not represent an Integer' do
        it 'returns an Array of the prefix as a Symbol and the Integer' do
          [0, 1, 10, 100, 23_456].each do |number|
            %w(flibble dibble purple doggie doo).each do |playlist|
              expect(
                subject.parse_playlist_reference_url("#{playlist}/#{number}")
              ).to eq([playlist.to_sym, number])
            end
          end
        end
      end
    end

    context 'when given a String with a slash followed by a non-Integer' do
      specify do
        expect { subject.parse_playlist_reference_url('squir/tle') }.to(
          raise_error
        )
      end
    end

    context 'when given something that is not a String' do
      specify do
        expect { subject.parse_playlist_reference_url(nil) }.to(
          raise_error
        )
      end
    end
  end

  describe '#parse_playlist_reference_hash' do
    let(:test) { -> { subject.parse_playlist_reference_hash(hash) } }

    shared_examples 'a normal call with an index' do
      context 'when :index is given and is an Integer' do
        let(:index) { 22 }

        it 'returns an Array containing a playlist ID and the Integer' do
          expect(test.call).to eq([expected_playlist, 22])
        end
      end

      context 'when :index is given as a String representing an Integer' do
        let(:index) { '44' }

        it 'returns an Array containing a playlist ID and the Integer' do
          expect(test.call).to eq([expected_playlist, 44])
        end
      end

      context 'when :index is given as a String not representing an Integer' do
        let(:index) { 'zerg' }

        specify { expect { test.call }.to(raise_error) }
      end

      context 'when :index is nil' do
        let(:index) { nil }

        specify { expect { test.call }.to(raise_error) }
      end
    end

    context 'when given a Hash with no :playlist key' do
      let(:hash)              { { index: index } }
      let(:expected_playlist) { subject.local_playlist_id }

      it_behaves_like 'a normal call with an index'

      context 'and :index is not given' do
        let(:hash) { {} }

        specify { expect { test.call }.to(raise_error) }
      end
    end

    context 'when given a Hash with a :playlist key' do
      let(:hash)              { { playlist: playlist, index: index } }
      let(:expected_playlist) { playlist.to_sym }

      context 'and :playlist is an Integer' do
        let(:playlist) { 20 }
        let(:expected_playlist) { playlist }

        it_behaves_like 'a normal call with an index'

        context 'and :index is not given' do
          let(:hash) { { playlist: playlist } }

          specify { expect { test.call }.to(raise_error) }
        end
      end

      context 'and :playlist is a string representing an Integer' do
        let(:playlist) { '20' }
        let(:expected_playlist) { Integer(playlist) }

        it_behaves_like 'a normal call with an index'

        context 'and :index is not given' do
          let(:hash) { { playlist: playlist } }

          specify { expect { test.call }.to(raise_error) }
        end
      end

      context 'and :playlist is a string not representing an Integer' do
        let(:playlist) { 'a_playlist' }

        it_behaves_like 'a normal call with an index'

        context 'and :index is not given' do
          let(:hash) { { playlist: playlist } }

          specify { expect { test.call }.to(raise_error) }
        end
      end

      context 'and :playlist is a symbol' do
        let(:playlist) { :a_playlist }

        it_behaves_like 'a normal call with an index'

        context 'and :index is not given' do
          let(:hash) { { playlist: playlist } }

          specify { expect { test.call }.to(raise_error) }
        end
      end
    end

    context 'given an empty hash' do
      let(:hash) { {} }

      specify { expect { test.call }.to(raise_error) }
    end

    context 'when given nil' do
      let(:hash) { nil }

      specify { expect { test.call }.to(raise_error) }
    end
  end
end
