require 'ury_rapid/model'

module Rapid
  module Model
    module Structures
      def self.player_tree(players)
        fail 'Nil player set given.' if players.nil?

        lambda do |*|
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
        end
      end

      def self.playlist_tree(playlists)
        fail 'Nil playlist set given.' if playlists.nil?

        lambda do |*|
           tree :playlists, :playlist_set do
            playlists.each { |playlist| list playlist, :playlist }
          end
        end
      end

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
        player_tree = Structures.player_tree(players)
        playlist_tree = Structures.playlist_tree(playlists)

        lambda do |*|
          instance_eval(&player_tree)
          instance_eval(&playlist_tree)
        end
      end
    end
  end
end
