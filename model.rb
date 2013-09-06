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

    # Public: Access the channel's currently loaded track for reading.
    attr_reader :loaded

    # Internal: Access the channel's currently loaded track for writing.
    attr_writer :loaded

    # Public: Access the channel's current state for reading.
    attr_reader :state

    # Public: Access the channel's current position for reading.
    attr_reader :position

    # Public: Access the channel's current position for writing.
    attr_writer :position

    # Public: Access the channel's current cue position for reading.
    attr_reader :cue

    # Public: Access the channel's current cue position for writing.
    attr_writer :cue

    # Public: Access the channel's current intro position for reading.
    attr_reader :intro

    # Public: Access the channel's current intro position for writing.
    attr_writer :intro

    # Internal: Initialises a Channel.
    #
    # id - The ID number of the channel.
    def initialize(id)
      @id = id
      @items = []
      @state = :stopped
      @cue = 0
      @intro = 0
      @position = 0
      @loaded = nil
    end

    # Public: Change the channel model's state.
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

    # Internal: Add an item to the channel.
    #
    # index - The position in the playlist in which this item should be added.
    # item  - An Item object representing the item to be added.
    #
    # Returns nothing.
    def add_item(index, item)
      @items[index] = item
    end
  end

  # Public: An item in the playout system.
  class Item
    # Public: Access the track type.
    attr_reader :type

    # Public: Access the track name.
    attr_reader :name

    def initialize(type, name)
      type = TYPE_SYMBOLS[type] if type.is_a? Numeric
      valid_type = %i{null library file text}.include? type
      raise 'Not a valid type' unless valid_type

      @type = type
      @name = name
    end

    private

    TYPE_SYMBOLS = {
      TrackTypes::NULL => :null,
      TrackTypes::LIBRARY => :library,
      TrackTypes::FILE => :file,
      TrackTypes::TEXT => :text
    }
  end
end
