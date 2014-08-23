require 'bra/model/model_object'
require 'compo'

module Bra
  module Model
    # A model object containing a constant value
    class Constant < Compo::Branches::Constant
      extend Forwardable
      include ModelObject

      alias_method :flat, :value
      def_delegator :@value, :to_s
    end
  end
end
