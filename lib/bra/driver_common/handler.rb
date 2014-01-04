module Bra
  module DriverCommon
    # Base class for request and response handlers.
    #
    # See Bra::DriverCommon::Requests::Handler and
    # Bra::DriverCommon::Responses::Handler for the more specific base classes.
    class Handler
      # Initialises the Handler
      #
      # @api semipublic
      #
      # @example Initialising a Handler with a parent Requester.
      #   queue = EventMachine::Queue.new
      #   requester = Bra::Baps::Requests::Requester.new(queue)
      #   handler = Bra::Baps::Requests::Handler.new(requester)
      #
      # @param parent [Requester] The main Requester to which requests shall
      #   be sent.
      def initialize(parent)
        @parent = parent
      end

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

      def self.has_targets?
        defined?(self::TARGETS) && !(self::TARGETS.empty?)
      end

      # Adds this handler's targets into the given handler set.
      def self.register_into(set)
        self::TARGETS.each do |target|
          set.register_handler(target, ->(*args) { new(*args).run })
        end
      end
    end
  end
end
