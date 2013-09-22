require_relative 'models/channel'
require_relative 'models/model_object'
require_relative 'models/player'
require_relative 'models/item'

module Bra
  module Models
    # Public: A model of the BAPS server state.
    class Model < HashModelObject
      # Public: Initialise the model.
      def initialize(num_channels)
        super()

        @channels = ChannelSet.new
        (0...num_channels).each do |i|
          channel = Channel.new
          channel.move_to(@channels, i)
        end

        @channels.move_to(self, :channels)
      end

      def name
        'Model'
      end

      def channels
        child(:channels)
      end

      # Public: Access one of the playback channels.
      #
      # number - The number of the channel (0-(num_channels - 1)).
      #
      # Returns the Channel object.
      def channel(number)
        channels.channel(Integer(number))
      end

      # Public: Access one of the playback channel players.
      #
      # number - The number of the channel (0-(num_channels - 1)).
      #
      # Returns the Player object.
      def player(number)
        channels.player(number)
      end

      # Public: Access one of the playback channel playlists.
      #
      # number - The number of the channel (0-(num_channels - 1)).
      #
      # Returns the Playlist object.
      def playlist(number)
        channels.playlist(number)
      end

      # Public: Gets the state of one of the channel players.
      #
      # number - The number of the channel (0 onwards).
      #
      # Returns the state (one of :playing, :paused or :stopped).
      def player_state(number)
        channels.player_state(number)
      end

      # Public: Gets the load state of one of the channel players.
      #
      # number - The number of the channel (0 onwards).
      #
      # Returns the load state.
      def player_load_state(number)
        channels.player_load_state(number)
      end

      # Public: Sets the state of one of the channel players.
      #
      # number - The number of the channel (0 onwards).
      # state  - The new state (one of :playing, :paused or :stopped).
      #
      # Returns nothing.
      def set_player_state(number, state)
        channels.set_player_state(number, state)
      end

      # Public: Gets the position of one of the player markers.
      #
      # number   - The number of the channel (0 onwards).
      # type     - The marker type (:position, :cue, :intro or :duration).
      #
      # Returns the marker position.
      def player_marker(number, type)
        channels.player_marker(number, type)
      end

      # Public: Sets the position of one of the channel player markers.
      #
      # number   - The number of the channel (0 onwards).
      # type     - The marker type (:position, :cue, :intro or :duration).
      # position - The new position, as a non-negative integer or coercible.
      #
      # Returns nothing.
      def set_player_marker(number, type, position)
        channels.set_player_marker(number, type, position)
      end

      # Public: Change the current item and load state for a channel player.
      #
      # number    - The number of the channel (0 onwards).
      # new_state - The symbol (must be one of :ok, :loading or :failed)
      #             representing the new state.
      # new_item  - The Item representing the new loaded item.
      def load_in_player(number, new_state, new_item)
        channels.load_in_player(number, new_state, new_item)
      end

      # Public: Return the item at the given index of the playlist for the
      # channel with the given ID.
      #
      # number    - The number of the channel (0 onwards).
      # index     - The index into the playlist, also as an integer starting
      #             from 0 or any Integer-coercible type.
      #
      # Returns an array representing the playlist data
      def playlist_item(number, index)
        channels.playlist_item(number, index)
      end

      # Public: Returns the canonical URL of the model channel list.
      #
      # Returns the URL, relative to the API root.
      def url
        resource_name
      end

      def parent_url
        fail('Tried to get parent URL of the model root.')
      end

      def resource_name
        ''
      end
    end
  end
end
