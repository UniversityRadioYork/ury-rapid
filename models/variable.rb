module Bra
  module Models
    # A model object containing a constant value.
    #
    # This is effectively a thin wrapper over a value, granting the ability to
    # treat it as a ModelObject while allowing any methods Constant doesn't
    # define to be responded to by the value.
    class Constant < SingleModelObject
      attr_reader :value, :get_privileges

      # The flat representation of a Constant is just its value.
      alias_method :to_jsonable, :value

      # Initialises the Constant object.
      #
      # @param value [Object] - The value of the constant.
      # @param privileges [Array] - The array of privilege symbols that will be
      #   required to GET this object.
      #
      def initialize(value, privileges)
        @value = value
        @get_privileges = privileges
      end

      # Override method_missing to redirect method requests to the value.
      def self.method_missing(symbol, *args)
        @value.public_send(symbol, *args)
      end

      # Override respond_to_missing? to redirect it to the value.
      def self.respond_to_missing?(symbol)
        @value.respond_to?(symbol)
      end

      # @return [String] The value as a string.
      def to_s
        # This isn't caught by method_missing, as it's defined for Object.
        # Thanks, Obama!
        @value.to_s
      end
    end

    # ModelObjects representing a single mutable variable.
    class Variable < Constant
      # Public: Allows direct read access to the value.
      attr_reader :value

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
      # get_privileges
      # edit_privileges - A list of symbols representing privileges required
      #                   to edit this variable.
      def initialize(initial_value, validator, get_privileges, edit_privileges)
        super(initial_value, get_privileges)
        @initial_value = initial_value
        @validator = validator
        @edit_privileges = edit_privileges
      end

      def value=(new_value)
        validated = new_value if @validator.nil?
        validated = @validator.call(new_value) unless @validator.nil?
        @value = validated
      end

      # Handle an attempt to put a new value into the PlayerVariable
      # from the API.
      #
      # @param resource [Object] A hash (which should have one item, a mapping
      #   from this variable's ID to its new value), or the new value itself.
      def put_do(resource)
        value = resource[id] if resource.is_a?(Hash)
        value = resource unless resource.is_a?(Hash)
        @value = value
      end

      # Public: Resets the variable to its default value.
      #
      # Returns nothing.
      def reset
        @value = initial_value
      end

      alias_method :delete, :reset

      # The driver_XYZ methods allow the driver to perform modifications to the
      # model using the same verbs as the server without triggering the usual
      # handlers.  They are implemented using the _do methods.
      alias_method :driver_put, :put_do
      alias_method :driver_delete, :delete_do

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
