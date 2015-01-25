require 'ury_rapid/model'
require 'ury_rapid/services/requests/null_handler'
require 'ury_rapid/model/components/creator'
require 'ury_rapid/model/components/creator_wrapper'

module Rapid
  module Model
    module Components
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
      class Creator
        extend Forwardable

        # Initialise a Creator
        def initialize(url, view, registrar)
          fail('Registrar must be callable.') unless registrar.respond_to?(:call)

          @url = url
          @view = view
          @registrar = registrar
        end

        def default_component_creator
          CreatorWrapper.new(Creator.new, @registrar)
        end

        def self.insert(*args, &block)
          Inserter.new(*args).instance_eval(&block)
        end

        # Handles a call to a missing method
        #
        # An Inserter regards any message it cannot directly handle as a
        # request for a component constructed by the Creator.
        def method_missing(symbol, *args, &block)
          if @creator.respond_to?(symbol)
            component(symbol, *args, &block)
          else
            super
          end
        end

        # Checks whether Inserter can handle a given method
        #
        # An Inserter regards any message it cannot directly handle as a
        # request for a component constructed by the Creator.
        def respond_to?(symbol)
          @creator.respond_to?(symbol) || super
        end

        private

        # Create a stock model component using the component creator
        # @return [void]
        def component(type, id, *args, &block)
          new_component = @creator.send(type, *args)
          @view.insert(@url, id, new_component)

          child_url = "#{@url.chomp('/')}/#{id}"
          build_children(child_url, &block) unless block.nil?
        end

        # Recursively invokes an Inserter for children of a model object
        def build_children(child_url, &block)
          child_ci = Inserter.new(child_url, @view, @registrar, @options)
          child_ci.instance_eval(&block)
        end
      end
    end
  end
end
