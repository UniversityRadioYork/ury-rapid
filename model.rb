require_relative 'models/channel'
require_relative 'models/model_object'
require_relative 'models/player'

module Bra
  module Models
    # Public: A model of the BAPS server state.
    class Model < ModelObject
      # Public: Allows access to one of the model's playback channels.
      attr_reader :channels

      # Public: Initialise the model.
      def initialize(num_channels)
        super('Model')

        @channels = (0...num_channels).map { |i| Channel.new(i, self) }
      end

      # Public: Access one of the playback channels.
      #
      # number - The number of the channel (0-(num_channels - 1)).
      #
      # Returns the Channel object.
      def channel(number)
        @channels[Integer(number)]
      end

      # Public: Access one of the playback channel players.
      #
      # number - The number of the channel (0-(num_channels - 1)).
      #
      # Returns the Player object.
      def player(number)
        channel(number).player
      end

      # Public: Access one of the playback channel playlists.
      #
      # number - The number of the channel (0-(num_channels - 1)).
      #
      # Returns the Playlist object.
      def playlist(number)
        channel(number).playlist
      end

      # Public: Gets the state of one of the channel players.
      #
      # number - The number of the channel (0 onwards).
      #
      # Returns the state (one of :playing, :paused or :stopped).
      def player_state(number)
        channel(number).player_state
      end

      # Public: Gets the load state of one of the channel players.
      #
      # number - The number of the channel (0 onwards).
      #
      # Returns the load state.
      def player_load_state(number)
        channel(number).player_load_state
      end

      # Public: Sets the state of one of the channel players.
      #
      # number - The number of the channel (0 onwards).
      # state  - The new state (one of :playing, :paused or :stopped).
      #
      # Returns nothing.
      def set_player_state(number, state)
        channel(number).set_player_state(state)
      end

      # Public: Gets the position of one of the player markers.
      #
      # number   - The number of the channel (0 onwards).
      # type     - The marker type (:position, :cue, :intro or :duration).
      #
      # Returns the marker position.
      def player_marker(number, type)
        channel(number).player_marker(type)
      end

      # Public: Sets the position of one of the channel player markers.
      #
      # number   - The number of the channel (0 onwards).
      # type     - The marker type (:position, :cue, :intro or :duration).
      # position - The new position, as a non-negative integer or coercible.
      #
      # Returns nothing.
      def set_player_marker(number, type, position)
        channel(number).set_player_marker(type, position)
      end

      # Public: Change the current item and load state for a channel player.
      #
      # number    - The number of the channel (0 onwards).
      # new_state - The symbol (must be one of :ok, :loading or :failed)
      #             representing the new state.
      # new_item  - The Item representing the new loaded item.
      def load_in_player(number, new_state, new_item)
        player(number).load(new_state, new_item)
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
        playlist(number).item(index)
      end

      # Public: Converts the Model to a hash representation.
      #
      # This conversion is not reversible and may lose some information.
      #
      # Returns a hash representation of the Model.
      def to_hash
        {
          channels: @channels.map { |channel| channel.to_hash }
        }
      end

      # Public: Returns the canonical URL of the model root.
      #
      # Returns the URL, relative to the API root.
      def url
        '/'
      end

      # Public: Returns the canonical URL of the model channel list.
      #
      # Returns the URL, relative to the API root.
      def channels_url
        '/channels'
      end
    end
  end
end
