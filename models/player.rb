require_relative 'channel'
require_relative 'variable'
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
      # @return [void]
      def set_state(new_state)
        state.value = new_state
      end

      # Public: Gets one of the player markers.
      #
      # type     - The marker type (:position, :cue, :intro or :duration).
      # position - The new position, as a non-negative integer or coercible.
      #
      # @return [void]
      def marker(type)
        child(type)
      end

      # Public: Sets the position of one of the player markers.
      #
      # type     - The marker type (:position, :cue, :intro or :duration).
      # position - The new position, as a non-negative integer or coercible.
      #
      # @return [void]
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
      # @return [void]
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
      # @return [void]
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
    class PlayerVariable < Variable
      def self.make_state
        new(:stopped, method(:validate_state), [], [:SetPlayerState])
      end

      def self.make_load_state
        new(:empty, method(:validate_load_state), [], nil)
      end

      def self.make_marker
        new(0, method(:validate_marker), [], [:SetMarker])
      end

      # Internal: Returns the channel this player component is inside.
      #
      # Returns the channel ID.
      def player_channel
        parent.channel
      end

      ##
      # Returns the ID of this parent's channel.
      def player_channel_id
        parent.channel_id
      end

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
    end
  end
end
