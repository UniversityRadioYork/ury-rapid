require 'ury-rapid/model'

module Rapid
  module Model
    module Structures
      # A basic model structure for playout system services
      #
      # This contains:
      #   - A player set, with IDs set in the model config under 'players'
      #   - A playlist set, with IDs set in the model config under 'playlists'
      class PlayoutModel < Rapid::Model::Creator
        include Rapid::Common::Types::Validators

        # Create the model from the given configuration
        #
        # @return [Root]  The finished model.
        def create
          root :playout_root do
            base_structure
            playout_extensions
          end
        end

        protected

        def playout_extensions
        end

        private

        def base_structure
          hashes :players, :player_set, option(:players), :player do
            component :state,      :play_state, :stopped
            component :load_state, :load_state, :empty
            component :volume,     :volume,     0.0
            markers
          end

          lists :playlists, :playlist_set, option(:playlists), :playlist
        end

        def markers
          Rapid::Common::Types::MARKERS.each { |m| component m, :marker, m, 0 }
        end
      end
    end
  end
end
