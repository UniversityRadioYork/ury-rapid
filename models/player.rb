require_relative 'channel'
require_relative '../utils/hash'

module Bra
  module Models
    # Public: A player in the model, which represents a channel's currently
    # playing song and its state.
    class Player < HashModelObject
      alias_method :channel, :parent
      alias_method :channel_id, :parent_id

      # Public: Access the player's current item for reading.
      attr_reader :item
      attr_writer :item
      alias_method :link_item, :item=

      def state
        child(:state)
      end

      def load_state
        child(:load_state)
      end

      # Public: Retrieves the player's state value.
      #
      # Returns the state value, as a symbol.
      def state_value
        state.value
      end

      # Public: Change the player model's state.
      #
      # new_state - The symbol representing the new state.
      #
      # Returns nothing.
      def set_state(new_state)
        state.value = new_state
      end

      # Public: Gets one of the player markers.
      #
      # type     - The marker type (:position, :cue, :intro or :duration).
      # position - The new position, as a non-negative integer or coercible.
      #
      # Returns nothing.
      def marker(type)
        child(type)
      end

      # Public: Sets the position of one of the player markers.
      #
      # type     - The marker type (:position, :cue, :intro or :duration).
      # position - The new position, as a non-negative integer or coercible.
      #
      # Returns nothing.
      def set_marker(type, position)
        marker(type).value = position
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

      # Public: Returns a hash of marker position values.
      #
      # Returns a hash mapping marker names to their raw position values.
      def marker_values
        @markers.transform_values { |marker| marker.value }
      end

      # Internal: Removes an item from the player.
      #
      # item - The item to unlink.  This must be the same as the item currently
      #        loaded.
      #
      # Returns nothing.
      def unlink_item(item)
        fail("Tried to unlink wrong item from #{name}") unless item == @item
      end

      def get_privileges
        []
      end

      private

      # Internal: Change the player model's load state.
      #
      # new_state - The symbol representing the new state.
      #
      # Returns nothing.
      def set_load_state(new_state)
        child(:load_state).value = new_state
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
    class PlayerVariable < SingleModelObject
      # Public: Allows direct read access to the value.
      attr_reader :value
      alias_method :to_jsonable, :value

      attr_reader :edit_privileges
      alias_method :put_privileges, :edit_privileges
      alias_method :post_privileges, :edit_privileges
      alias_method :delete_privileges, :edit_privileges

      def self.make_state
        new(:stopped, method(:validate_state), [:SetPlayerState])
      end

      def self.make_load_state
        new(:empty, method(:validate_load_state), nil)
      end

      def self.make_marker
        new(0, method(:validate_marker), [:SetMarker])
      end

      # Internal: Initialises a PlayerVariable.
      #
      # name            - The name of the variable.
      # player          - The Player the variable is attached to.
      # initial_value   - The initial value for the PlayerVariable.
      # validator       - A proc that, given a new value, will raise an
      #                   exception if the value is invalid and return a
      #                   sanitised version of the value otherwise.
      #                   Can be nil.
      # edit_privileges - A list of symbols representing privileges required
      #                   to edit this variable.
      def initialize(initial_value, validator, edit_privileges)
        super()
        @initial_value = initial_value
        @value = initial_value
        @validator = validator
        @edit_privileges = edit_privileges
      end

      def value=(new_value)
        validated = new_value if @validator.nil?
        validated = @validator.call(new_value) unless @validator.nil?
        @value = validated
      end

      # Public: Handle an attempt to put a new value into the PlayerVariable
      # from the API.
      #
      # new_value - A hash (which should have one item, a mapping from
      #             this variable's ID to its new value), or the new value
      #             itself.
      #
      # Returns nothing.
      def put_do(new_value)
        value = new_value[id] if value.is_a?(Hash)
        value ||= new_value
        @value = value
      end

      # Public: Resets the variable to its default value.
      #
      # Returns nothing.
      def reset
        @value = initial_value
      end

      alias_method :delete, :reset

      # Internal: Returns the channel this player component is inside.
      #
      # Returns the channel ID.
      def player_channel
        parent.channel
      end

      def get_privileges
        []
      end

      # The driver_XYZ methods allow the driver to perform modifications to the
      # model using the same verbs as the server without triggering the usual
      # handlers.  They are implemented using the _do methods.
      alias_method :driver_put, :put_do
      alias_method :driver_delete, :delete_do

      private

      # Internal: Validates an incoming marker.
      #
      # new_marker - The incoming marker position.
      #
      # Returns the validated state.
      # Raises an exception if the value is invalid.
      def self.validate_marker(position)
        position ||= 0
        position_int = Integer(position)
        fail('Position is negative.') if position_int < 0
        # TODO: Check against duration?
        position_int
      end

      # Internal: Validates an incoming player state.
      #
      # new_state - The incoming player state.
      #
      # Returns the validated state.
      # Raises an exception if the value is invalid.
      def self.validate_state(new_state)
        validate_symbol(new_state, %i(playing paused stopped))
      end

      # Internal: Validates an incoming player load state.
      #
      # new_state - The incoming player load state.
      #
      # Returns the validated state.
      # Raises an exception if the value is invalid.
      def self.validate_load_state(new_state)
        validate_symbol(new_state, %i(ok loading failed empty))
      end

      # Internal: Validates an incoming symbol.
      #
      # new_symbol - The incoming symbol.
      # candidates - A list of allowed symbols.
      #
      # Returns the validated symbol.
      # Raises an exception if the value is invalid.
      def self.validate_symbol(new_symbol, candidates)
        # TODO: convert strings to symbols
        fail(
          "Expected one of #{candidates}, got #{new_symbol}"
        ) unless candidates.include?(new_symbol)
        new_symbol
      end
    end
  end
end
