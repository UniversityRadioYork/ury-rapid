require 'bra/model'

module Bra
  module Model
    module Structures
      # A basic 
      #
      # This contains:
      #   - A player set, with IDs set in the model config under 'players'
      #   - A playlist set, with IDs set in the model config under 'playlists'
      class PlayoutModel < Bra::Model::Creator
        include Bra::Common::Types::Validators

        # Create the model from the given configuration
        #
        # @return [Root]  The finished model.
        def create
          root do
            base_structure
            playout_extensions
          end
        end

        protected

        def playout_extensions
        end

        private

        def base_structure
          hashes    :players, :player_set, option(:players), :player do
            component :state,      :play_state, :stopped
            component :load_state, :load_state, :empty
            component :volume,     :volume,     0.0
            markers
          end

          lists     :playlists, :playlist_set, option(:playlists), :playlist
        end

        def markers
          Bra::Common::Types::MARKERS.each { |m| component m, :marker, m, 0 }
        end
      end
    end
  end
end