require 'bra/models/model_object'

module Bra
  module Models
    # A model object containing a constant value.
    #
    # This is effectively a thin wrapper over a value, granting the ability to
    # treat it as a ModelObject while allowing any methods Constant doesn't
    # define to be responded to by the value.
    class Constant < ModelObject
      extend Forwardable

      attr_reader :value

      # The flat representation of a Constant is its value.
      alias_method :flat, :value

      # Initialises the Constant object.
      #
      # @param value [Object] The value of the constant.
      # @param handler_target [Symbol] The handler target of the constant (for
      #   privilege retrieval).
      #
      def initialize(value, handler_target = nil)
        @value = value
        @handler_target = handler_target
      end

      def_delegator :@value, :public_send, :method_missing
      def_delegator :@value, :respond_to?, :respond_to_missing?
      def_delegator :@value, :to_s
    end

    # A model object representing a single mutable variable
    #
    # This is effectively a Constant whose value can be PUT, DELETEd and
    # POSTed by both the server (handler permitting) and the driver.  It keeps
    # track of its initial value, to which it will be set if DELETEd by the
    # driver.
    class Variable < Constant
      # Allows direct read access to the initial value
      attr_reader :initial_value

      # Initialises a Variable
      #
      # @api public
      # @example  Initialising a Variable with no validator.
      #
      # @param initial_value [Object]  The initial value for the Variable.
      # @param validator [Object] - A callable that, given a new value, will
      #   raise an exception if the value is invalid and return a sanitised
      #   version of the value otherwise.  Can be nil, in which case no
      #   validation is performed.
      # @param handler_target [Symbol] The name under which this variable's
      #   handlers are defined; if nil, use the default (see
      #   ModelObject#handler_target).
      def initialize(initial_value, validator, handler_target = nil)
        super(initial_value, handler_target)
        @initial_value = initial_value
        @validator = validator
        @handler_target = handler_target
      end

      # Put a new value into this Variable
      #
      # This is intended to be used by the driver.  For the server, see #put.
      #
      # If this Variable has a validator, the new value will be sent through
      # that validator and the result placed into the Variable.
      #
      # If this results in a value change, the update channel will be notified.
      #
      # @api public
      # @example  Put the value 'test' into a Variable.
      #   variable.driver_put('test')
      #
      # @param new_value [Object]   The value to put in the Variable.
      #
      # @return [void]
      def driver_put(new_value)
        value = validate_if_possible(new_value)
        # Only bother changing a variable's value and propagating the update
        # if the value has actually changed.
        if @value != value
          @value = value
          notify_update
        end
      end

      # Resets the variable to its default value
      #
      # This is exactly equivalent to calling #driver_put with #initial_value.
      # The notes on #driver_put thus also apply to this function.
      #
      # @api public
      # @example Calling driver_delete.
      #   variable.driver_delete
      #
      # @return [void]
      def driver_delete
        driver_put(initial_value)
      end

      private

      # Validates the incoming value, or passes it on if there is no validator
      #
      # @api private
      #
      # @param new_value  The intended new value, which must be validated.
      #
      # @return [Object]  The result of calling the validator on new_value, if
      #   it exists, or new_value otherwise.
      def validate_if_possible(new_value)
        @validator.nil? ? new_value : @validator.call(new_value)
      end
    end
  end
end
