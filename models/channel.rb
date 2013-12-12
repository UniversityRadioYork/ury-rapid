require_relative 'composite'

module Bra
  module Models
    # Wrapper around a list of channels.
    class ChannelSet < ListModelObject
      alias_method :channels, :children
      alias_method :channel, :child
    end

    # A channel in the BAPS server state.
    class Channel < HashModelObject
      def player
        child(:player)
      end

      def playlist
        child(:playlist)
      end

      # Clears the channel's playlist.
      #
      # @return [void]
      def clear_playlist
        playlist.clear
      end
    end

    # A channel playlist, consisting of a list of playlist items.
    class Playlist < ListModelObject
      extend Forwardable

      alias_method :channel_id, :parent_id

      def_delegator :@children, :size

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
      def driver_post(id, item)
        item.register_update_channel(@update_channel)
        item.move_to(self, id)
        item.notify_update
      end
    end
  end
end
