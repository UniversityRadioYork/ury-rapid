require 'ury_rapid/model'
require 'ury_rapid/service_common/requests/null_handler'
require 'ury_rapid/model/component_creator'

module Rapid
  module Model
    # Option-based creator for models
    #
    # This performs dependency injection and ensures any model modification
    # handlers specified in the options are set up.
    #
    # It does not handle service-specific model additions beyond method hook
    # registrations; to add new model trees to the model, pass the result of
    # the model creator to other functions.
    #
    # Usually you will want to subclass this and override #create, to create a
    # model structure definition.
    class ComponentInserter
      extend Forwardable

      # Initialise a Creator
      def initialize(url, view, registrar, options = {})
        fail('Registrar must be callable.') unless registrar.respond_to?(:call)

        @url       = url
        @view      = view
        @options   = options
        @registrar = registrar

        @component_creator = options.fetch(:component_creator,
                                           default_component_creator)
      end

      def default_component_creator
        ComponentCreator.new(@registrar)
      end

      def self.insert(*args, &block)
        ComponentInserter.new(*args).instance_eval(&block)
      end

      COMPOSITES = [[:hash, :hashes, HashModelObject],
                    [:list, :lists, ListModelObject]]
      COMPOSITES.each do |(singular, plural, composite_class)|
        define_method(singular) do |id, handler_target, &block|
          child(id, composite_class.new(handler_target), &block)
        end

        define_method(plural) do |set_id, set_tgt, child_ids, child_tgt, &block|
          hash(set_id, set_tgt) do
            child_ids.each do |id|
              child(id, composite_class.new(child_tgt), &block)
            end
          end
        end
      end

      # Handles a call to a missing method
      #
      # A ComponentInserter regards any message it cannot directly handle as a
      # request for a component constructed by ComponentCreator.
      def method_missing(symbol, *args, &block)
        if @component_creator.respond_to?(symbol)
          component(symbol, *args, &block)
        else
          super
        end
      end

      # Checks whether ComponentInserter can handle a given method
      #
      # A ComponentInserter regards any message it cannot directly handle as a
      # request for a component constructed by ComponentCreator.
      def respond_to?(symbol)
        @component_creator.respond_to?(symbol) || super
      end

      private

      def child(id, object, &block)
        object = object.new if object.is_a?(Class)
        @registrar.call(object)
        child_url = "#{@url.chomp('/')}/#{id}"

        @view.insert(@url, id, object)
        build_children(child_url, object, &block) unless block.nil?
      end

      # Create a stock model component using the component creator
      def component(type, id, *args, &block)
        child(id, @component_creator.send(type, *args, &block))
      end

      # Recursively invokes a ComponentInserter for children of a model object
      def build_children(child_url, child, &block)
        child_ci = ComponentInserter.new(child_url, @view, @registrar, @options)
        child_ci.instance_eval(&block)
      end
    end
  end
end
