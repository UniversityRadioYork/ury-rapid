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
