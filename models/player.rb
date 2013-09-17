require_relative 'channel'

module Bra
  module Models
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

      # Public: Access the player's current duration for reading.
      attr_reader :duration

      # Public: Access the player's current cue position for reading.
      attr_reader :cue

      # Public: Access the player's current intro position for reading.
      attr_reader :intro

      # Public: Initialises a Player.
      #
      # channel - The channel of the player.
      def initialize(channel)
        super('Player', channel)

        @state = make_variable('State', :stopped, :validate_state)
        @load_state = make_variable('Load State', :ok, :validate_load_state)
        @cue = make_position('Cue')
        @intro = make_position('Intro')
        @position = make_position('Position')
        @duration = make_position('Duration')
        @loaded = nil
      end

      # Public: Retrieves the player's state value.
      #
      # Returns the state value, as a symbol.
      def state_value
        @state.value
      end

      # Public: Change the player model's state.
      #
      # new_state - The symbol representing the new state.
      #
      # Returns nothing.
      def set_state(new_state)
        @state.value = new_state
      end

      # Public: Sets the position of one of the player markers.
      #
      # type     - The marker type (:position, :cue, :intro or :duration).
      # position - The new position, as a non-negative integer or coercible.
      #
      # Returns nothing.
      def set_marker(type, position)
        marker = {
          cue: @cue,
          duration: @duration,
          intro: @intro,
          position: @position
        }[type]
        fail("Unknown marker type: #{type}.") if marker.nil?
        marker.value = position
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
        set_load_state(new_state)
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

      # Public: Returns the canonical URL of this player.
      #
      # Returns the URL, relative to the API root.
      def url
        [@channel.url, 'player'].join('/')
      end

      # Public: Returns the canonical URL of this player's parent.
      #
      # Returns the URL, relative to the API root.
      def parent_url
        @channel.url
      end

      private

      # Internal: Makes a new player variable.
      #
      # name          - The name of the variable.
      # initial_value - The initial value of the variable.
      # validator     - A filter that validates and returns new values.
      #
      # Returns the PlayerVariable constructed from the above.
      def make_variable(name, initial_value, validator)
        PlayerVariable.new(name, self, initial_value, method(validator))
      end

      # Internal: Makes a new player position variable.
      #
      # name          - The name of the variable.
      #
      # Returns the PlayerVariable constructed from the above.
      def make_position(name)
        make_variable(name, 0, :validate_position)
      end

      # Internal: Validates an incoming position.
      #
      # new_position - The incoming position.
      #
      # Returns the validated state nothing.
      # Raises an exception if the value is invalid.
      def validate_position(new_position)
        position_int = Integer(new_position)
        fail('Position is negative.') if position_int < 0
        # TODO: Check against duration
        position_int
      end

      # Internal: Validates an incoming player state.
      #
      # new_state - The incoming player state.
      #
      # Returns the validated state.
      # Raises an exception if the value is invalid.
      def validate_state(new_state)
        validate_symbol(new_state, %i(playing paused stopped))
      end

      # Internal: Validates an incoming player load state.
      #
      # new_state - The incoming player load state.
      #
      # Returns the validated state.
      # Raises an exception if the value is invalid.
      def validate_load_state(new_state)
        validate_symbol(new_state, %i(ok loading failed empty))
      end

      # Internal: Validates an incoming symbol.
      #
      # new_symbol - The incoming symbol.
      # candidates - A list of allowed symbols.
      #
      # Returns the validated symbol.
      # Raises an exception if the value is invalid.
      def validate_symbol(new_symbol, candidates)
        # TODO: convert strings to symbols
        fail(
          "Expected one of #{candidates}, got #{new_symbol}"
        ) unless candidates.include?(new_symbol)
        new_symbol
      end

      # Internal: Change the player model's load state.
      #
      # new_state - The symbol representing the new state.
      #
      # Returns nothing.
      def set_load_state(new_state)
        @load_state.value = new_state
      end
    end

    class PlayerComponent < ModelObject
      def initialize(name, player)
        super("#{name} (#{player.name}")
        @player = player
      end

      # Internal: Returns the ID of the channel this player component is
      # inside.
      #
      # Returns the channel ID.
      def player_channel_id
        @player.channel_id
      end

      # Internal: Returns the name of the channel this player component is
      # inside.
      #
      # Returns the channel name.
      def player_channel_name
        @player.channel_name
      end
    end

    # Public: A container for a player variable.
    #
    # This container exists to make the traversal of the API at the variable
    # level easier; player variables have a defined parent, so one can deduce
    # the player to whom the variable belongs from the variable itself.
    #
    # Player variables also have validation, so that broken controllers can be
    # discovered.
    class PlayerVariable < PlayerComponent
      # Public: Allows direct read access to the value.
      attr_reader :value

      # Internal: Initialises a PlayerVariable.
      #
      # name          - The name of the variable.
      # player        - The Player the variable is attached to.
      # initial_value - The initial value for the PlayerVariable.
      # validator     - A proc that, given a new value, will raise an exception
      #                 if the value is invalid and return a sanitised version
      #                 of the value otherwise.  Can be nil.
      def initialize(name, player, initial_value, validator)
        super(name, player)
        @value = initial_value
        @validator = validator
      end

      def value=(new_value)
        validated = new_value if @validator.nil?
        validated = @validator.call(new_value) unless @validator.nil?
        @value = validated
      end

      def to_json
        @value.to_json
      end
    end
  end
end
