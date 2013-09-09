module Bra
  # Public: A model of the BAPS server state.
  class Model
    # Public: Allows access to one of the model's playback channels.
    attr_reader :channels

    # Public: Initialise the model.
    def initialize
      @channels = []
      3.times { |i| @channels.push Channel.new(i) }
    end

    # Public: Access one of the playback channels.
    #
    # number - The number of the channel (0-3).
    #
    # Returns the Channel object.
    def channel(number)
      @channels[number]
    end
  end

  # Public: A channel in the BAPS server state.
  class Channel
    # Public: Access the channel's ID for reading.
    attr_reader :id

    # Public: Access the channel items set for reading.
    attr_reader :items

    # Internal: Access the channel items set for writing.
    attr_writer :items

    # Public: Access the channel's player model for reading.
    attr_reader :player

    # Internal: Access the channel's player model for writing.
    attr_writer :player

    # Internal: Initialises a Channel.
    #
    # id - The ID number of the channel.
    def initialize(id)
      @id = id
      @items = []
      @player = Player.new

    end

    # Internal: Add an item to the channel.
    #
    # index - The position in the playlist in which this item should be added.
    # item  - An Item object representing the item to be added.
    #
    # Returns nothing.
    def add_item(index, item)
      @items[index] = item
    end

    # Internal: Clears the channel's playlist.
    #
    # Returns nothing.
    def clear_playlist
      @items = []
    end
  end

  # Public: An item in the playout system.
  class Item
    # Public: Access the track type.
    attr_reader :type

    # Public: Access the track name.
    attr_reader :name

    def initialize(type, name)
      valid_type = %i{library file text}.include? type
      raise "Not a valid type: #{type}" unless valid_type

      @type = type
      @name = name
    end

  end

  # Public: A player in the model, which represents a channel's currently
  # playing song and its state.
  class Player
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
    def initialize
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
  end
end
