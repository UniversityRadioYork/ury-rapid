require_relative 'model_object'

module Bra
  module Models
    # Public: An item in the playout system.
    class Item < ModelObject
      # Public: Access the track type.
      attr_reader :type

      def initialize(type, name)
        super(name)

        valid_type = %i{library file text}.include? type
        raise "Not a valid type: #{type}" unless valid_type

        @type = type
        @parent = nil
        @index = nil
      end

      # Public: Moves the Item to a playlist.
      #
      # new_parent - The new parent for the Item.
      # new_index  - The index to move to.  This only makes sense if the
      #              parent is a Playlist.
      #
      # Returns nothing.
      def move_to(new_parent, new_index=nil)
        @parent.unlink_item(self) unless @parent.nil?

        new_parent.link_item(self, new_index)
        @parent = new_parent
        @index = new_index
      end

      # Public: Converts the Item to a hash representation.
      #
      # This conversion is not reversible and may lose some information.
      #
      # Returns a hash representation of the Item.
      def to_hash
        { name: @name, type: @type }
      end

      def url
        # If we've got an index, then that's where we appear in the URL
        # structure. If we don't, assume we're the only item child of our
        # parent, so we're called just 'item'.
        index_string = @index.to_s unless @index.nil?
        index_string = 'item' if @index.nil?

        [parent_url, index_string].join('/')
      end

      def parent_url
        @parent.url
      end

      def parent_name
        @parent.name
      end
    end
  end
end
