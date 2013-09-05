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

    # Public: Access the channel items set for writing.
    attr_writer :items

    # Public: Access the channel state for reading.
    attr_reader :state

    def initialize(id)
      @id = id
      @items = []
      @state = :stopped
    end

    # Public: Changes the channel model's state.
    #
    # new_state - The symbol (must be one of :playing, :paused or :stopped)
    #             representing the new state.
    def state=(new_state)
      valid_state = new_state.in? %i(playing paused stopped)
      @state = new_state if valid_state
      raise 'Not a valid state' unless valid_state
    end
  end
end
