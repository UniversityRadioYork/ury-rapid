require_relative 'composite'
require_relative 'variable'
require_relative 'item'
require_relative '../utils/hash'

module Bra
  module Models
    class PlayerSet < HashModelObject
    end

    # Public: A player in the model, which represents a channel's currently
    # playing song and its state.
    class Player < HashModelObject
      include ItemContainer
    end

    # A container for a player variable
    #
    # This container exists to make the traversal of the API at the variable
    # level easier; player variables have a defined parent, so one can deduce
    # the player to whom the variable belongs from the variable itself.
    #
    # Player variables also have validation, so that broken controllers can be
    # discovered.
    class PlayerVariable < Variable
      def self.make_state
        new(:stopped, method(:validate_state), :player_state)
      end

      def self.make_load_state
        new(:empty, method(:validate_load_state), :player_load_state)
      end

      def self.make_marker(id)
        new(0, method(:validate_marker), "player_#{id}".intern)
      end

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
