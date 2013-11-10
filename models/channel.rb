require_relative 'composite'

module Bra
  module Models
    # Wrapper around a list of channels.
    class ChannelSet < ListModelObject
      alias_method :channels, :children
      alias_method :channel, :child

      def channel_count
        children.size
      end

      # Access one of the playback channel players.
      #
      # number - The number of the channel (0-(num_channels - 1)).
      #
      # Returns the Player object.
      def player(number)
        channel(number).player
      end

      # Access one of the playback channel playlists.
      #
      # number - The number of the channel (0-(num_channels - 1)).
      #
      # Returns the Playlist object.
      def playlist(number)
        channel(number).playlist
      end

      # Gets the state of one of the channel players.
      #
      # number - The number of the channel (0 onwards).
      #
      # Returns the state (one of :playing, :paused or :stopped).
      def player_state(number)
        channel(number).player_state
      end

      # Gets the load state of one of the channel players.
      #
      # number - The number of the channel (0 onwards).
      #
      # Returns the load state.
      def player_load_state(number)
        channel(number).player_load_state
      end

      # Gets the position of one of the player markers.
      #
      # number   - The number of the channel (0 onwards).
      # type     - The marker type (:position, :cue, :intro or :duration).
      #
      # Returns the marker position.
      def player_marker(number, type)
        channel(number).player_marker(type)
      end

      # Change the current item and load state for a channel player.
      #
      # number    - The number of the channel (0 onwards).
      # new_state - The symbol (must be one of :ok, :loading or :failed)
      #             representing the new state.
      # new_item  - The Item representing the new loaded item.
      def load_in_player(number, new_state, new_item)
        channel(number).load_in_player(new_state, new_item)
      end

      # Return the item at the given index of the playlist for the
      # channel with the given ID.
      #
      # number    - The number of the channel (0 onwards).
      # index     - The index into the playlist, also as an integer starting
      #             from 0 or any Integer-coercible type.
      #
      # Returns an array representing the playlist data
      def playlist_item(number, index)
        channel(number).playlist_item(index)
      end

      def get_privileges
        []
      end
    end

    # A channel in the BAPS server state.
    class Channel < HashModelObject
      # Change the current item and load state for a channel player.
      #
      # new_state - The symbol (must be one of :ok, :loading or :failed)
      #             representing the new state.
      # new_item  - The Item representing the new loaded item.
      def load_in_player(new_state, new_item)
        player.load(new_state, new_item)
      end

      def player
        child(:player)
      end

      def playlist
        child(:playlist)
      end

      # List the items in the channel's playlist.
      #
      # index - The index whose item is requested (starting from 0).
      #
      # Returns the item at the given index on the playlist, or nil if none
      #   exists.
      def playlist_item(index)
        playlist.item(index)
      end

      # List the items in the channel's playlist.
      #
      # Returns a list of Item objects in the playlist.
      def playlist_contents
        playlist.contents
      end

      # Retrieves the channel's player state.
      #
      # Returns the player state.
      def player_state
        player.state
      end

      # Retrieves the channel's player's state value.
      #
      # Returns the state value, as a symbol.
      def player_state_value
        player.state_value
      end

      # Gets the position of one of the player markers.
      #
      # type - The marker type (:position, :cue, :intro or :duration).
      #
      # Returns the marker position.
      def player_marker(type)
        player.marker(type)
      end

      # Retrieves the channel's player load state.
      #
      # Returns the player load state.
      def player_load_state
        player.load_state
      end

      # Returns the number of items in the playlist.
      #
      # Returns the playlist item count.
      def playlist_size
        playlist.size
      end

      # Clears the channel's playlist.
      #
      # @return [void]
      def clear_playlist
        playlist.clear
      end

      def get_privileges
        []
      end
    end

    ##
    # A channel playlist, consisting of a list of playlist items.
    class Playlist < ListModelObject
      # Returns the number of items in the playlist
      #
      # Returns the playlist item count.
      def size
        children.size
      end

      def get_privileges
        []
      end
    end
  end
end
