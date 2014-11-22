require 'ury_rapid/common/exceptions'

module Rapid
  module Services
    # Base class for request and response handlers.
    #
    # See Rapid::Services::Requests::Handler and
    # Rapid::Services::Responses::Handler for the more specific base
    # classes.
    class Handler
      extend Forwardable

      # Initialises the Handler
      #
      # @api semipublic
      #
      # @example Initialising a Handler with a parent Requester.
      #   queue = EventMachine::Queue.new
      #   requester = Rapid::Baps::Requests::Requester.new(queue)
      #   handler = Rapid::Baps::Requests::Handler.new(requester)
      #
      # @param in_parent [Requester]
      #   The main Requester to which requests shall be sent.
      def initialize(in_parent)
        @parent = in_parent
      end

      # It's the handler set's responsibility to provide a way for the handler
      # to log things.
      delegate :log => :parent

      def targets
        self.class::TARGETS
      end

      def self.def_targets(*targets)
        const_set('TARGETS', targets)
      end

      def self.use_poster(poster_class, *actions)
        actions.each do |action|
          define_method(action) do |object, payload|
            poster_class.post(payload, self, object)
          end
        end
      end

      def self.targets?
        defined?(self::TARGETS) && !(self::TARGETS.empty?)
      end

      # Adds this handler's targets into the given handler set.
      def self.register_into(set)
        self::TARGETS.each do |target|
          set.register_handler(target, ->(*args) { new(set, *args).run })
          set.log(:info, "Registered #{self} for #{target}.")
        end
      end

      protected

      attr_reader :parent

      # Raises an error signifying an action is unimplemented by Rapid
      def unimplemented_by_bra
        fail(Rapid::Common::Exceptions::NotSupportedByRapid)
      end

      # Raises an error signifying an action is unimplemented by the service
      def unimplemented_by_service
        fail(Rapid::Common::Exceptions::NotSupportedByService)
      end
    end
  end
end
