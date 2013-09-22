require_relative 'model_object'

module Bra
  module Models
    # Public: An item in the playout system.
    class Item < HashModelObject
      # Public: Access the track type.
      attr_reader :type

      def initialize(type, name)
        super(nil, name)

        valid_type = %i(library file text).include? type
        raise "Not a valid type: #{type}" unless valid_type

        @type = type
        @index = nil
      end

      # Public: Moves the Item to a playlist.
      #
      # new_parent - The new parent for the Item.
      # new_index  - The index to move to.  This only makes sense if the
      #              parent is a Playlist.
      #
      # Returns nothing.
      def enqueue(new_parent, new_index=nil)
        @parent.remove_child(self) unless @parent.nil?

        @index = new_index
        @parent = new_parent

        new_parent.add_child(self) unless @parent.nil?
      end

      # Public: Converts the Item to a hash representation.
      #
      # This conversion is not reversible and may lose some information.
      #
      # Returns a hash representation of the Item.
      def to_hash
        { name: @name, type: @type }
      end

      def resource_name
        # If we've got an index, then that's where we appear in the URL
        # structure. If we don't, assume we're the only item child of our
        # parent, so we're called just 'item'.
        @index.nil? ? 'item' : @index.to_s
      end
    end
  end
end
