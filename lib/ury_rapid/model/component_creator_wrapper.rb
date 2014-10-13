require 'delegate'

module Rapid
  module Model
    # An object that wraps a ComponentCreator
    #
    # A ComponentCreatorWrapper allows a hook proc to be run after every use
    # of a ComponentCreator.  Usually, this hook is some sort of registrar
    # function that adds things like update channels and handlers to created
    # components.
    class ComponentCreatorWrapper < SimpleDelegator
      def initialize(creator, hook)
        super(creator)
        @hook = hook
      end

      def method_missing(*args)
        super(*args).tap(&@hook)
      end
    end
  end
end
