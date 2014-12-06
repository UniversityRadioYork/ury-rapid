require 'ury_rapid/model/model_object'
require 'compo'

module Rapid
  module Model
    # A model object containing a constant value
    class Constant < Compo::Branches::Constant
      extend Forwardable
      include ModelObject

      alias_method :flat, :value

      delegate %i(to_s) => :value
    end
  end
end
