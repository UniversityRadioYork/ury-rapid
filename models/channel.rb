require_relative 'model_object'

module Bra
  module Models
    # Internal: An object associated with a BRA channel.
    class ChannelComponent < ModelObject
      # Public: Allows read access to the object's channel.
      attr_reader :channel

      def initialize(name, channel)
        super("#{name} (#{channel.name})")
        @channel = channel
      end

      # Public: Retrieve the ID of the player's channel.
      #
      # Returns the aforementioned ID.
      def channel_id
        @channel.id
      end

      # Public: Retrieve the name of the player's channel.
      #
      # Returns the aforementioned name.
      def channel_name
        @channel.name
      end
    end

    # Public: A channel in the BAPS server state.
    class Channel < ModelObject
      # Public: Access the channel's ID for reading.
      attr_reader :id

      # Public: Access the channel items set for reading.
      attr_reader :items

      # Public: Access the channel's player model for reading.
      attr_reader :player

      # Public: Access the channel's playlist model for reading.
      attr_reader :playlist

      # Internal: Initialises a Channel.
      #
      # id   - The ID number of the channel.
      # root - The model root.
      def initialize(id, root)
        super("Channel #{id}")

        @id = id
        @items = []
        @player = Player.new(self)
        @playlist = Playlist.new(self)
        @root = root
      end

      # Internal: Add an item to the channel.
      #
      # index - The position in the playlist in which this item should be
      #         added.
      # item  - An Item object representing the item to be added.
      #
      # Returns nothing.
      def add_item(index, item)
        @playlist.add_item(index, item)
      end

      # Internal: List the items in the channel's playlist.
      #
      # Returns a list of Item objects in the playlist.
      def playlist_contents
        @playlist.contents
      end

      # Public: Retrieves the channel's player state.
      #
      # Returns the player state.
      def player_state
        @player.state
      end

      # Public: Retrieves the channel's player's state value.
      #
      # Returns the state value, as a symbol.
      def player_state_value
        @player.state_value
      end

      # Public: Sets the channel's player state.
      #
      # new_state - The new state to use.
      #
      # Returns nothing.
      def set_player_state(new_state)
        @player.set_state(new_state)
      end

      # Public: Gets the position of one of the player markers.
      #
      # type - The marker type (:position, :cue, :intro or :duration).
      #
      # Returns the marker position.
      def player_marker(type)
        @player.marker(type)
      end

      # Public: Sets the position of one of the player markers.
      #
      # type     - The marker type (:position, :cue, :intro or :duration).
      # position - The new position, as a non-negative integer or coercible.
      #
      # Returns nothing.
      def set_player_marker(type, position)
        @player.set_marker(type, position)
      end

      # Public: Retrieves the channel's player load state.
      #
      # Returns the player load state.
      def player_load_state
        @player.load_state
      end

      # Internal: Returns the number of items in the playlist.
      #
      # Returns the playlist item count.
      def playlist_size
        @playlist.size
      end

      # Internal: Clears the channel's playlist.
      #
      # Returns nothing.
      def clear_playlist
        @playlist.clear
      end

      # Public: Converts the Channel to a hash representation.
      #
      # This conversion is not reversible and may lose some information.
      #
      # Returns a hash representation of the Channel.
      def to_hash
        {
          id: @id,
          items: @items.map { |item| item.to_hash },
          player: @player.to_hash
        }
      end

      # Public: Returns the canonical URL of this channel.
      #
      # Returns the URL, relative to the API root.
      def url
        [@root.channels_url, @id].join('/')
      end

      # Public: Returns the canonical URL of this channel's parent.
      #
      # Returns the URL, relative to the API root.
      def parent_url
        @root.channels_url
      end
    end

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


    class Playlist < ChannelComponent
      # Internal: Allows read access to the playlist items.
      attr_reader :contents

      def initialize(channel)
        super('Playlist', channel)

        @contents = []
      end

      # Internal: Add an item to the channel.
      #
      # index - The position in the playlist in which this item should be
      #         added.
      # item  - An Item object representing the item to be added.
      #
      # Returns nothing.
      def add_item(index, item)
        item.move_to(self, index)
      end

      # Internal: Retrieves an item in the channel.
      #
      # index - The index whose item is to be retrieved.
      #
      # Returns the Item, or nil if none exists at the given index.
      def item(index)
        @contents[Integer(index)]
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
        @contents.size
      end

      # Public: Returns the canonical URL of this playlist.
      #
      # Returns the URL, relative to the API root.
      def url
        [@channel.url, 'playlist'].join('/')
      end

      # Public: Returns the canonical URL of this playlist's parent.
      #
      # Returns the URL, relative to the API root.
      def parent_url
        @channel.url
      end

      # Public: Converts the playlist to JSON.
      #
      # Returns a JSON representation of the playlist.
      def to_json(*args)
        @contents.to_json(*args)
      end

      # Internal: Removes an item from the playlist.
      #
      # item - The item to unlink.  This must be the same as the item currently
      #        loaded.
      #
      # Returns nothing.
      def unlink_item(item)
        @contents.delete(item)
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
        @contents[index] = item
      end
    end
  end
end
