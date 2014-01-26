require 'bra/model'

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
      extend Forwardable

      # Initialise a Creator
      def initialize(update_channel, logger, options)
        @handlers = Hash.new(Bra::DriverCommon::Requests::NullHandler.new)
        @logger = logger
        @options = options
        @update_channel = update_channel
        @component_creator = Bra::Model::ComponentCreator.new(self)

        @target = nil
      end

      def add_handlers(handlers)
        @handlers.merge!(handlers)
      end

      protected

      def_delegator :@component_creator, :public_send, :create_model_object
      def_delegator :@options, [], :option

      #
      # Model creation DSL
      #

      # Creates a log object
      def log(id)
        child id, create_model_object(:log, @logger)
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

      def hashes(set_id, set_target, child_ids, child_target, &block)
        set(
          set_id, set_target, HashModelObject, child_ids, child_target, &block
        )
      end

      def lists(set_id, set_target, child_ids, child_target, &block)
        set(
          set_id, set_target, ListModelObject, child_ids, child_target, &block
        )
      end

      def set(set_id, set_target, child_class, child_ids, child_target, &block)
        puts "#{set_id} #{set_target} #{child_class} #{child_ids} #{child_target}"
        hash(set_id, set_target) do
          children(child_ids, child_class, child_target, &block)
        end
      end

      # Creates a ListModelObject with the given handler target and ID
      def list(id, handler_target, &block)
        child(id, new_list(handler_target), &block)
      end

      def new_list(*args)
        ListModelObject.new(*args)
      end

      # Creates a HashModelObject with the given handler target and ID
      def hash(id, handler_target, &block)
        child(id, new_hash(handler_target), &block)
      end

      def new_hash(*args)
        HashModelObject.new(*args)
      end

      def class_to_set_target(member_class)
        class_name = member_class.name.demodulize.underscore
        "#{class_name}_set".intern
      end

      def children(ids, child_class, *new_args, &block)
        ids.each { |id| child(id, child_class.new(*new_args), &block) }
      end

      def root(object = nil, &block)
        build(object || new_hash(:root), &block)
      end

      def build(object, &block)
        object = object.new if object.is_a?(Class)
        register(object)
        build_children(object, &block) if block
        object
      end

      def child(id, object, &block)
        @target.add(id, build(object, &block))
      end

      # Create a stock model component using the model configurator
      def component(id, type, *args, &block)
        child(id, create_model_object(type, *args), &block)
      end

      def build_children(object)
        target = @target
        @target = object
        yield
        @target = target
      end

      def register(object)
        register_handler(object)
        register_update_channel(object)
      end

      private

      def register_handler(object)
        object.register_handler(handler_for(object))
      end

      def register_update_channel(object)
        object.register_update_channel(@update_channel)
      end

      def handler_for(object)
        @handlers[object.handler_target]
      end
    end
  end
end
