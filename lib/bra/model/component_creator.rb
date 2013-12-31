require 'bra/common/types'
require 'bra/model'

module Bra
  module Model
    class ComponentCreator
      include Bra::Common::Types::Validators

      def initialize(registrar)
      end

      def load_state(value)
        Bra::Model::Constant.new(validate_load_state(value), :load_state)
      end

      def play_state(value)
        Bra::Model::Constant.new(validate_play_state(value), :state)
      end
    end
  end
end
