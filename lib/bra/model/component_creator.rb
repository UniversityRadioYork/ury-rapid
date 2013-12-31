require 'bra/common/types'
require 'bra/model'

module Bra
  module Model
    class ComponentCreator
      include Bra::Common::Types::Validators

      def create(type, value)
        case type
        when :load_state
          Bra::Model::Constant.new(validate_load_state(value), :load_state)
        when :play_state
          Bra::Model::Constant.new(validate_play_state(value), :state)
        end
      end
    end
  end
end
