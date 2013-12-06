module Bra
  module DriverCommon
    # Base class for driver classes that manage a set of handlers
    #
    # A handler is a class that provides some function in handling driver
    # requests or responses, from server and playout system actions
    # respectively.
    #
    # NOTE: Subclasses must define the constant HANDLER_MODULE.
    class HandlerSet

      protected

      # Populates a hash mapping handler targets to their handlers in this set
      def handler_hash
        handlers.reduce({}, &method(:add_handler_targets))
      end

      def handler_module
        self.class::HANDLER_MODULE
      end

      private

      def add_handler_targets(hash, handler_class)
        make_and_register(hash, handler_class) if has_targets?(handler_class)
        hash
      end

      def has_targets?(handler_class)
        valid_class?(handler_class) ? handler_class.has_targets? : false
      end

      def valid_class?(handler_class)
        handler_class.respond_to?(:has_targets?)
      end

      def make_and_register(hash, handler_class)
        handler = handler_class.new(self)
        hash.merge!(handler.target_hash)
        puts "Registered handler #{handler_class.name} for #{handler.targets}"
      end

      # Compiles a list of all handlers to register
      #
      # This is everything require'd by the Requester that is in the
      # Bra::Baps::Requests::Handlers module.
      #
      # @return [Array] An array of handlers as described above.
      def handlers
        handler_module.constants.map(&handler_module.method(:const_get))
      end
    end
  end
end
