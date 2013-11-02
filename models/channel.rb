require_relative 'model_object'

module Bra
  module Models
    # Public: Wrapper around a list of channels.
    class ChannelSet < ListModelObject
      alias_method :channels, :children
      alias_method :channel, :child

      def channel_count
        children.size
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
        channel(number).load_in_player(new_state, new_item)
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
        channel(number).playlist_item(index)
      end

      def get_privileges
        []
      end
    end

    # Public: A channel in the BAPS server state.
    class Channel < HashModelObject
      def name
        "Channel #{id}"
      end

      # Internal: Change the current item and load state for a channel player.
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

      # Internal: Add an item to the channel.
      #
      # index - The position in the playlist in which this item should be
      #         added.
      # item  - An Item object representing the item to be added.
      #
      # Returns nothing.
      def add_item(index, item)
        playlist.add_item(index, item)
      end

      # Internal: List the items in the channel's playlist.
      #
      # index - The index whose item is requested (starting from 0).
      #
      # Returns the item at the given index on the playlist, or nil if none
      #   exists.
      def playlist_item(index)
        playlist.item(index)
      end

      # Internal: List the items in the channel's playlist.
      #
      # Returns a list of Item objects in the playlist.
      def playlist_contents
        playlist.contents
      end

      # Public: Retrieves the channel's player state.
      #
      # Returns the player state.
      def player_state
        player.state
      end

      # Public: Retrieves the channel's player's state value.
      #
      # Returns the state value, as a symbol.
      def player_state_value
        player.state_value
      end

      # Public: Sets the channel's player state.
      #
      # new_state - The new state to use.
      #
      # Returns nothing.
      def set_player_state(new_state)
        player.set_state(new_state)
      end

      # Public: Gets the position of one of the player markers.
      #
      # type - The marker type (:position, :cue, :intro or :duration).
      #
      # Returns the marker position.
      def player_marker(type)
        player.marker(type)
      end

      # Public: Sets the position of one of the player markers.
      #
      # type     - The marker type (:position, :cue, :intro or :duration).
      # position - The new position, as a non-negative integer or coercible.
      #
      # Returns nothing.
      def set_player_marker(type, position)
        player.set_marker(type, position)
      end

      # Public: Retrieves the channel's player load state.
      #
      # Returns the player load state.
      def player_load_state
        player.load_state
      end

      # Internal: Returns the number of items in the playlist.
      #
      # Returns the playlist item count.
      def playlist_size
        playlist.size
      end

      # Internal: Clears the channel's playlist.
      #
      # Returns nothing.
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
      alias_method :contents, :children

      # Internal: Allows read access to the playlist items.
      attr_reader :children

      # Internal: Produces an array-of-hashes representation of this playlist.
      #
      # Returns an array of items represented as hashes.
      def content_hashes
        children.map { |item| item.to_hash }
      end

      # Internal: Add an item to the channel.
      #
      # index - The position in the playlist in which this item should be
      #         added.
      # item  - An Item object representing the item to be added.
      #
      # Returns nothing.
      def add_item(index, item)
        item.enqueue(self, index)
      end

      # Internal: Retrieves an item in the channel.
      #
      # index - The index whose item is to be retrieved.
      #
      # Returns the Item, or nil if none exists at the given index.
      def item(index)
        child(index)
      end

      # Internal: Clears the playlist.
      #
      # Returns nothing.
      def clear
        @contents = []
      end

      # Internal: Returns the number of items in the playlist.
      #
      # Returns the playlist item count.
      def size
        children.size
      end

      def resource_name
        'playlist'
      end

      # Public: Converts the playlist to a JSON-able format.
      #
      # Returns a JSON-ready representation of the playlist.
      def to_jsonable
        children.map { |item| item.to_jsonable }
      end

      # Internal: Removes an item from the playlist.
      #
      # item - The item to unlink.  This must be the same as the item currently
      #        loaded.
      #
      # Returns nothing.
      def unlink_item(item)
        remove_child(item)
      end

      # Internal: Puts an item into the playlist.
      #
      # This does not register the item's parent.
      #
      # item  - The item to link.
      # index - The index to link the item into.
      #
      # Returns nothing.
      def link_item(item, index)
        add_child(item)
        @contents[index] = item
      end

      def get_privileges
        []
      end
    end
  end
end
