require_relative 'model_object'

module Bra
  module Models
    # A model object containing a constant value.
    #
    # This is effectively a thin wrapper over a value, granting the ability to
    # treat it as a ModelObject while allowing any methods Constant doesn't
    # define to be responded to by the value.
    class Constant < SingleModelObject
      extend Forwardable

      attr_reader :value, :handler_target

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

      # The name under which this object's handlers are defined
      #
      # @return (see Bra::Models::ModelObject#handler_target)
      def handler_target
        @handler_target.nil? ? super() : @handler_target
      end

      def_delegator :@value, :public_send, :method_missing
      def_delegator :@value, :respond_to?, :respond_to_missing?
      def_delegator :@value, :to_s
    end

    # ModelObjects representing a single mutable variable
    #
    # This adds to Constant the ability to write to the variable, privilege
    # specification for performing PUT/POST/DELETE, and the ability to validate
    # model inputs.
    class Variable < Constant
      # Allows direct read access to the initial value
      attr_reader :initial_value

      # Initialises a Variable
      #
      # initial_value   - The initial value for the PlayerVariable.
      # validator       - A proc that, given a new value, will raise an
      #                   exception if the value is invalid and return a
      #                   sanitised version of the value otherwise.
      #                   Can be nil.
      # @param handler_target [Symbol] The name under which this variable's
      #   handlers are defined; if nil, use the default (see
      #   ModelObject#handler_target).
      def initialize(initial_value, validator, handler_target = nil)
        super(initial_value, handler_target)
        @initial_value = initial_value
        @validator = validator
        @handler_target = handler_target
      end

      # Handle an attempt to put a new value into the PlayerVariable
      # from the API.
      #
      # @param resource [Object] A hash (which should have one item, a mapping
      #   from this variable's ID to its new value), or the new value itself.
      def driver_put(resource)
        value = validate_if_possible(resource)
        # Only bother changing a variable's value and propagating the update
        # if the value has actually changed.
        if @value != value
          @value = value
          notify_update
        end
      end

      # Public: Resets the variable to its default value.
      #
      # @return [void]
      def driver_delete
        driver_put(initial_value)
      end

      private

      def validate_if_possible(new_value)
        @validator.nil? ? new_value : @validator.call(new_value)
      end
    end
  end
end
