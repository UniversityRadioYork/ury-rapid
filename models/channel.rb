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

    # A channel playlist, consisting of a list of playlist items.
    class Playlist < ListModelObject
      extend Forwardable

      alias_method :channel_id, :parent_id

      def_delegator :@children, :size

      def get_privileges
        []
      end

      def delete_privileges
        [:EditPlaylist]
      end

      alias_method :post_privileges, :delete_privileges

      # POSTs a new Item into this Playlist.
      #
      # In order to request a specific index for the item, wrap the Item in a
      # Hash mapping that index to that item.  Any occupied indices will have
      # their item overwritten.
      #
      # @api semiprivate
      #
      # @example POST an Item into position 2.
      #   playlist.post_do({ 3 => Item.new(:library, 'Foo') })
      #
      # @param item [Object] Either a Hash mapping one integer index to one
      #   Item, or an Item by itself.
      #
      # @return [void]
      def post_do(item)
        index = nil
        index = children.size if item.is_a?(Item)
        index, item = item.flatten if item.is_a?(Hash)
        fail('Unknown item type.') if index.nil?

        item.move_to(self, Integer(index))
      end

      # The driver_XYZ methods allow the driver to perform modifications to the
      # model using the same verbs as the server without triggering the usual
      # handlers.  They are implemented using the _do methods.
      alias_method :driver_put, :put_do
      alias_method :driver_delete, :delete_do
      alias_method :driver_post, :post_do
    end
  end
end
