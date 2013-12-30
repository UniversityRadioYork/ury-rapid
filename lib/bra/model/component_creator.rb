require 'bra/common/types'
require 'bra/model'

module Bra
  module Model
    class ComponentCreator
      def create(type, value)
        case type
        when :load_state
          fail unless Bra::Common::Types::LOAD_STATES.include? value
          Bra::Model::Constant.new(value, :load_state)
        when :play_state
          fail unless Bra::Common::Types::PLAY_STATES.include? value
          Bra::Model::Constant.new(value, :state)
        end
      end
    end
  end
end
