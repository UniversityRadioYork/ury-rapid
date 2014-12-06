module Rapid
  module Services
    # Base class for service classes that manage a set of handlers
    #
    # A handler is a class that provides some function in handling service
    # requests or responses, from server and playout system actions
    # respectively.
    #
    # NOTE: Subclasses must define the constant HANDLER_MODULE, as well as a
    #   function #log which takes a severity symbol and string and logs it.
    class HandlerSet
      extend Forwardable

      def initialize
        @handlers = {}
        populate(handler_classes)
      end

      def_delegator :handlers, :[]=, :register_handler

      protected

      attr_reader :handlers

      # Populates a hash mapping handler targets to their handlers in this set
      def populate(classes)
        classes.each(&method(:add_handler_targets))
      end

      def handler_module
        self.class::HANDLER_MODULE
      end

      private

      def add_handler_targets(handler_class)
        handler_class.register_into(self) if targets?(handler_class)
      end

      def targets?(handler_class)
        valid_class?(handler_class) && handler_class.targets?
      end

      def valid_class?(handler_class)
        handler_class.respond_to?(:targets?)
      end

      # Compiles a list of all handlers to register
      #
      # This is everything require'd by the Requester that is in the
      # Rapid::Baps::Requests::Handlers module.
      #
      # @return [Array] An array of handlers as described above.
      def handler_classes
        handler_module.constants.map(&handler_module.method(:const_get))
      end
    end
  end
end
