require_relative 'channel'
require_relative 'variable'
require_relative '../utils/hash'

module Bra
  module Models
    class PlayerSet < HashModelObject
    end

    # Public: A player in the model, which represents a channel's currently
    # playing song and its state.
    class Player < HashModelObject
      alias_method :channel, :parent
      alias_method :channel_id, :parent_id

      # Public: Access the player's current item for reading.
      attr_reader :item
      attr_writer :item
      alias_method :link_item, :item=

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

      def driver_post(id, resource)
        if id == :item
          resource.register_update_channel(@update_channel)
          resource.move_to(self, id)
          resource.notify_update
        else
          super(id, resource)
        end
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
      extend Forwardable

      def self.make_state
        new(:stopped, method(:validate_state), :player_state)
      end

      def self.make_load_state
        new(:empty, method(:validate_load_state), :player_load_state)
      end

      def self.make_marker(id)
        new(0, method(:validate_marker), "player_#{id}".intern)
      end

      def_delegator :@parent, :channel, :player_channel
      def_delegator :@parent, :channel_id, :player_channel_id

      # Validates an incoming marker
      #
      # @param new_marker [Integer] The incoming marker position.
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

      # Validates an incoming player state
      #
      # @param new_state [Symbol] The incoming player state.
      #
      # Returns the validated state.
      # Raises an exception if the value is invalid.
      def self.validate_state(new_state)
        validate_symbol(new_state, %i(playing paused stopped))
      end

      # Validates an incoming player load state
      #
      # @param new_state [Symbol] The incoming player load state.
      #
      # Returns the validated state.
      # Raises an exception if the value is invalid.
      def self.validate_load_state(new_state)
        validate_symbol(new_state, %i(ok loading failed empty))
      end
    end
  end
end
