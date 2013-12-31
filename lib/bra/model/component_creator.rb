require 'bra/common/types'
require 'bra/model'

module Bra
  module Model
    class ComponentCreator
      extend Forwardable

      include Bra::Common::Types::Validators

      def initialize(registrar)
        @registrar = registrar
      end

      def load_state(value)
        validate_then_constant(:validate_load_state, value, :load_state)
      end

      def play_state(value)
        validate_then_constant(:validate_play_state, value, :state)
      end

      private

      def validate_then_constant(validator, raw_value, handler_target)
        constant(send(validator, raw_value), handler_target)
      end

      def constant(value, handler_target)
        Bra::Model::Constant.new(value, handler_target).tap(&method(:register))
      end

      def_delegator :@registrar, :register
    end
  end
end
