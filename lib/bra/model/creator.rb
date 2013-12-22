require 'bra/model/variable'
require 'bra/model/composite'

module Bra
  module Model
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

      # Retrieves the model option with the given key
      def option(param)
        @options[param]
      end

      # Creates multiple Constants with the same handler target from a hash
      def constants(hash, handler_target)
        hash.each { |key, value| constant(key, value, handler_target) }
      end

      # Creates a Constant with the given ID, value and handler target
      def constant(id, value, handler_target)
        child id, Constant.new(value, handler_target)
      end

      # Creates a Variable with the given parameters
      def var(id, initial_value, handler_target, validator)
        child id, Variable.new(initial_value, validator, handler_target)
      end

      # Creates a Set of items with the given ID list and class
      def set_of(id, member_class, ids, &block)
        set(id, class_to_set_target(member_class)) do
          children(ids, member_class, &block)
        end
      end

      # Creates a Set with the given handler target and ID
      def set(id, handler_target, &block)
        child(id, HashModelObject.new(handler_target), &block)
      end

      def class_to_set_target(member_class)
        class_name = member_class.name.demodulize.underscore
        "#{class_name}_set".intern
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
