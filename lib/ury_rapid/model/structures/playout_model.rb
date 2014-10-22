require 'ury_rapid/model'

module Rapid
  module Model
    module Structures
      # A basic model structure for playout system services
      #
      # This contains:
      #   - A player set, with IDs set in the model config under 'players'
      #   - A playlist set, with IDs set in the model config under 'playlists'
      #
      # @param players [Array]
      #   An array of IDs of the players available in this playout system.
      # @param playlists [Array]
      #   An array of IDs of the playlists available in this playout system.
      # @return [Proc]
      #   A proc that may be instance_eval'd into an #insert_components stanza.
      def self.playout_model(players, playlists)
        ->(*) do
          fail 'Nil player set given.' if players.nil?
          fail 'Nil playlist set given.' if playlists.nil?

          tree :players, :player_set do
            players.each do |player|
              tree player, :player do
                play_state :state, :stopped
                load_state :load_state, :empty
                volume :volume, 0.0
                Rapid::Common::Types::MARKERS.each { |m| marker m, m, 0 }
              end
            end
          end

          tree :playlists, :playlist_set do
            playlists.each { |playlist| list playlist, :playlist }
          end
        end
      end
    end
  end
end
