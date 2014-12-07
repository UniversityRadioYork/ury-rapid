require 'ury_rapid/model'

module Rapid
  module Model
    module Structures
      # Many of these methods are designed in a weird way - they return lambdas
      # that do the actual work.  Why?  Because the lambdas will be instance
      # evaluated, and, thus will lose all context other than the local
      # variables closed over into their environment.

      # Returns a proc for generating the body of a channel
      #
      # This may be invoked directly by playout services that own precisely
      # one channel.
      #
      # @return [Proc]
      #   A proc that may be instance_eval'd into an #insert_components stanza.
      def self.channel_body
        player   = Structures.player
        playlist = Structures.playlist

        lambda do |*|
          instance_eval(&player)
          instance_eval(&playlist)
        end
      end

      # Returns a proc for generating a player tree
      #
      # @return [Proc]
      #   A proc that may be instance_eval'd into an #insert_components stanza.
      def self.player
        lambda do |*|
          tree :player, :player do
            play_state :state, :stopped
            load_state :load_state, :empty
            volume :volume, 0.0
            Rapid::Common::Types::MARKERS.each { |m| marker m, m, 0 }
          end
        end
      end

      # Returns a proc for generating a playlist
      #
      # @return [Proc]
      #   A proc that may be instance_eval'd into an #insert_components stanza.
      def self.playlist
        lambda { |*| list :playlist, :playlist }
      end

      # Returns a proc for generating a channel set
      #
      # @param channel_ids [Array]
      #   An array of the IDs of the channels available in this playout system.
      # @return [Proc]
      #   A proc that may be instance_eval'd into an #insert_components stanza.
      def self.channel_set_tree(channel_ids)
        fail 'Nil channel IDs array given.' if channel_ids.nil?

        channel_body = Structures.channel_body

        lambda do |*|
          tree :channels, :channel_set do
            channel_ids.each do |channel_id|
              tree(channel_id, :channel) { instance_eval(&channel_body) }
            end
          end
        end
      end

      # A basic model structure for playout system services
      #
      # This contains:
      #   - A channel set, with IDs set in the model config under 'players'
      #   - A playlist set, with IDs set in the model config under 'playlists'
      #
      # @param channel_ids [Array]
      #   An array of the IDs of the channels available in this playout system.
      # @return [Proc]
      #   A proc that may be instance_eval'd into an #insert_components stanza.
      def self.playout_model(channel_ids)
        channel_set_tree = Structures.channel_set_tree(channel_ids)

        lambda do |*|
          instance_eval(&channel_set_tree)
        end
      end
    end
  end
end
