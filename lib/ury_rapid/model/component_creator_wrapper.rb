require 'delegate'

module Rapid
  module Model
    # An object that wraps a ComponentCreator
    #
    # A ComponentCreatorWrapper allows a hook proc to be run after every use
    # of a ComponentCreator.  Usually, this hook is some sort of registrar
    # function that adds things like update channels and handlers to created
    # components.
    #
    # This class has a very buzzwordy name, but is mostly harmless.
    class ComponentCreatorWrapper < SimpleDelegator
      # Initialises a new ComponentCreatorWrapper
      #
      # @api public
      # @example Construct a useless ComponentCreatorWrapper that does nothing.
      #   ComponentCreatorWrapper.new(creator, ->(x) { x })
      # @param creator [ComponentCreator]
      #   The component creator to wrap.  Any messages not responded to directly
      #   by this ComponentCreatorWrapper are forwarded verbatim to the
      #   creator, with the hook invoked on the return value
      # @param hook [Object]
      #   An object (usually a Proc) that responds to a #call message
      #   containing a component by performing some action and returning back a
      #   component.  The component may be the original, or some transformation
      #   thereof.  The hook is invoked silently on any component created.
      def initialize(creator, hook)
        fail(ArgumentError, 'Hook not callable') unless hook.respond_to?(:call)

        super(creator)
        @hook = hook
      end

      # Delegates missing methods to the creator, invoking the hook on return
      def method_missing(*args)
        @hook.call(super(*args))
      end
    end
  end
end
