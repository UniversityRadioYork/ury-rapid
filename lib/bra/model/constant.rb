require 'bra/model/model_object'
require 'compo'

module Bra
  module Model
    # A model object containing a constant value
    class Constant < Compo::Branches::Constant
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
        super(handler_target, value)
      end

      alias_method :flat, :value
      def_delegator :@value, :to_s
    end
  end
end
