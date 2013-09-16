module Bra
  # Internal: An object in the BRA model.
  class ModelObject
    # Public: Allows read access to the object's name.
    attr_reader :name

    def initialize(name)
      @name = name
    end

    # Public: Converts a model object to JSON.
    #
    # This expects a to_hash method to be defined.
    #
    # Returns the JSON representation of the model object.
    def to_json
      to_hash.to_json
    end
  end

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

  # Public: A model of the BAPS server state.
  class Model < ModelObject
    # Public: Allows access to one of the model's playback channels.
    attr_reader :channels

    # Public: Initialise the model.
    def initialize(num_channels)
      super('Model')

      @channels = (0...num_channels).map { |i| Channel.new(i) }
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

    # Public: Sets the state of one of the channel players.
    #
    # number - The number of the channel (0 onwards).
    # state  - The new state (one of :playing, :paused or :stopped).
    #
    # Returns nothing.
    def set_player_state(number, state)
      channel(number).set_player_state(state)
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
    # id - The ID number of the channel.
    def initialize(id)
      super("Channel #{id}")

      @id = id
      @items = []
      @player = Player.new(self)
      @playlist = Playlist.new(self)
    end

    # Internal: Add an item to the channel.
    #
    # index - The position in the playlist in which this item should be added.
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

    # Public: Sets the channel's player state.
    #
    # new_state - The new state to use.
    #
    # Returns nothing.
    def set_player_state(new_state)
      @player.state = new_state
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
    end

    # Public: Converts the Item to a hash representation.
    #
    # This conversion is not reversible and may lose some information.
    #
    # Returns a hash representation of the Item.
    def to_hash
      { name: @name, type: @type }
    end
  end

  # Public: A player in the model, which represents a channel's currently
  # playing song and its state.
  class Player < ChannelComponent
    # Public: Access the player's current item for reading.
    attr_reader :item

    # Public: Access the player's current state for reading.
    attr_reader :state

    # Public: Access the player's loading state for reading.
    attr_reader :load_state

    # Public: Access the player's current position for reading.
    attr_reader :position

    # Public: Access the player's current position for writing.
    attr_writer :position

    # Public: Access the player's current duration for reading.
    attr_reader :duration

    # Public: Access the player's current duration for writing.
    attr_writer :duration

    # Public: Access the player's current cue position for reading.
    attr_reader :cue

    # Public: Access the player's current cue position for writing.
    attr_writer :cue

    # Public: Access the player's current intro position for reading.
    attr_reader :intro

    # Public: Access the player's current intro position for writing.
    attr_writer :intro

    # Public: Initialises a Player.
    #
    # channel - The channel of the player.
    def initialize(channel)
      super("Player", channel)

      @state = :stopped
      @load_state = :empty
      @cue = 0
      @intro = 0
      @position = 0
      @duration = 0
      @loaded = nil
    end

    # Public: Change the player model's state.
    #
    # new_state - The symbol (must be one of :playing, :paused or :stopped)
    #             representing the new state.
    #
    # Returns nothing.
    def state=(new_state)
      valid_state = %i(playing paused stopped).include? new_state
      raise 'Not a valid state' unless valid_state

      @state = new_state
    end

    # Public: Change the player model's current item and load state.
    #
    # new_state - The symbol (must be one of :ok, :loading or :failed)
    #             representing the new state.
    # new_item  - The Item representing the new loaded item.
    def load(new_state, new_item)
      valid_item = new_item.nil? || new_item.is_a?(Item)
      raise "Not a valid item: #{new_item}" unless valid_item
      @item = new_item

      valid_state = %i(ok loading failed empty).include? new_state
      raise 'Not a valid state' unless valid_state
      @load_state = new_state
    end

    # Public: Converts the Player to a hash representation.
    #
    # This conversion is not reversible and may lose some information.
    #
    # Returns a hash representation of the Player.
    def to_hash
      {
        item: @item.to_hash,
        position: position,
        cue: cue,
        intro: intro,
        state: state,
        load_state: load_state
      }
    end
  end

  class Playlist < ChannelComponent
    # Internal: Allows read access to the playlist items.
    attr_reader :contents

    def initialize(channel)
      super("Playlist", channel)

      @contents = []
    end

    # Internal: Add an item to the channel.
    #
    # index - The position in the playlist in which this item should be added.
    # item  - An Item object representing the item to be added.
    #
    # Returns nothing.
    def add_item(index, item)
      @contents[index] = item
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
  end
end
