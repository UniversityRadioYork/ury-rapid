require 'bra/model/model_object'
require 'compo'

module Bra
  module Model
    # A model object containing a constant value
    #
    # This is effectively a thin wrapper over a value, granting the ability to
    # treat it as a ModelObject while allowing any methods Constant doesn't
    # define to be responded to by the value.
    class Constant < Compo::Leaf
      extend Forwardable
      include ModelObject

      # Initialises the Constant
      #
      # @api public
      # @example  Initialising a Constant with the default handler target
      #   Constant.new(:value)
      # @example  Initialising a Constant with a specific handler target
      #   Constant.new(:value, :target)
      #
      # @param value [Object] The value of the constant.
      # @param handler_target [Symbol] The handler target of the constant (for
      #   privilege retrieval).
      #
      def initialize(value, handler_target = nil)
        super(handler_target)
        @value = value
      end

      # Returns the current value of this Constant
      #
      # @api public
      # @example  Retrieving a Constant's value.
      #   const = Constant.new(:spoon)
      #   const.value
      #   #=> :spoon
      #
      # @return [Object]  The Constant's internal value.
      attr_reader :value
      alias_method :flat, :value

      def_delegator :@value, :to_s
    end
  end
end
