require_relative 'set'

module Bra
  module Models
    # Option-based creator for models
    #
    # This performs dependency injection and ensures any model modification
    # handlers specified in the options are set up.
    #
    # It does not handle driver-specific model additions beyond method hook
    # registrations; to add new model trees to the model, pass the result of
    # the model creator to other functions.
    #
    # Usually you will want to subclass this and override #create, to create a
    # model structure definition.
    class Creator
      # Public: Initialise a Creator.
      #
      # options - The options hash to use to create models.
      def initialize(options)
        @options = options
        @channel = EventMachine::Channel.new
        @target = nil
      end

      protected

      def option(param)
        @options[param]
      end

      def set(id, member_class, ids, &block)
        child id, Set.new(member_class) do
          children(ids, member_class, &block)
        end
      end

      def children(ids, child_class, &block)
        ids.each { |id| child(id, child_class, &block) }
      end

      def root(object, &block)
        object = object.new if object.is_a?(Class)
        register(object)
        build_children(object, &block) if block
        object
      end

      def child(id, object, &block)
        root(object, &block).move_to(@target, id)
      end

      def var(target, validator, initial_value)
        Variable.new(initial_value, validator, target)
      end

      def build_children(object)
        target = @target
        @target = object
        yield
        @target = target
      end

      def register(object)
        register_handlers(object)
        register_update_channel(object)
      end

      # Attaches HTTP method handlers to a model resource
      #
      # The attached handlers will be @options[NAME][METHOD], where NAME is the
      #   handler_target of the object.
      #
      # @param object [ModelObject] The resource to which the handlers will
      #   be attached.
      #
      # @return [void]
      def register_handlers(object)
        handler = @options[object.handler_target]
        object.register_handler(handler) unless handler.nil?
        warn_no_handler_for(object) if handler.nil?
      end

      # Attaches the updates channel to a model resource
      #
      # The attached channel will be @options[:updates_channel].
      #
      # @param object [ModelObject] The resource to which the handlers will
      #   be attached.
      #
      # @return [void]
      def register_update_channel(object)
        channel = @options[:update_channel]
        object.register_update_channel(channel) unless channel.nil?
        fail('No update channel in @options[:update_channel].') if channel.nil?
      end

      def warn_no_handler_for(object)
        puts("No handler for target #{object.handler_target}.")
      end
    end
  end
end
