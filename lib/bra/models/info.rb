require_relative 'set'
require_relative 'variable'

module Bra
  module Models
    # Container for the bra information model.
    class Info < Bra::Models::Set
      def initialize
        super(Bra::Models::Constant)
      end

      def handler_target
        :info
      end
    end
  end
end
