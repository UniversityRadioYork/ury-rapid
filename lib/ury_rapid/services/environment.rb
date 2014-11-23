require 'ury_rapid/model/view'
require 'ury_rapid/model/component_inserter'
require 'ury_rapid/services/requests/null_handler'

module Rapid
  module Services
    # An environment object
    #
    # Every Service in Rapid is provided with an Environment, which represents
    # the Service's connection to the rest of Rapid.
    #
    # An Environment allows Services to:
    #
    # - Query (get/put/post/delete) any part of the Rapid model, as long as the
    #   Service can authenticate with enough privileges to perform the query;
    # - Directly modify (insert/replace/kill) its own part of the Rapid model;
    # - Insert components (pre-made model sub-structures) into its own part of
    #   the Rapid model;
    # - Perform authentication, either for itself or on behalf of an external
    #   client;
    # - Register to, and deregister from, the model updates channel.
    class Environment
      # For .def_delegator, .def_delegators, etc.
      extend Forwardable

      # Initialises an Environment
      #
      # @param authenticator [Object]
      #   An authenticator that can be used to construct privilege sets for
      #   global root queries.
      # @param update_channel [Rapid::Model::UpdateChannel]
      #   The model's update channel.
      # @param view [Rapid::Model::View]
      #   The view into the model that allows global queries and local updates.
      def initialize(authenticator, update_channel, view)
        @authenticator  = authenticator
        @update_channel = update_channel
        @view           = view
        @handlers       = Hash.new(Rapid::Services::Requests::NullHandler.new)
      end

      # Creates an Environment for the root service
      #
      # This contains a View that has the tip of the Rapid model as both its
      # local and global root.
      def self.for_root(authenticator, update_channel, root)
        Environment.new(authenticator,
                        update_channel,
                        Rapid::Model::View.new(root, root))
      end

      # Creates a new Environment from this one, substituting the View
      #
      # The new Environment will have no handlers registered.
      def with_view(new_view)
        Environment.new(authenticator, update_channel, new_view)
      end

      # Creates a new Environment from this one, substituting the local root
      #
      # This is usually used when creating a Service that is a child of an
      # existing Service: fork off the parent Service's Environment, changing
      # the View to point to the child Service's model.
      def with_local_root(local_root)
        with_view(view.with_local_root(local_root))
      end

      #
      # Re-exports from components
      #

      delegate %i(authenticate)             => :authenticator
      delegate %i(log
                  get put post delete
                  find insert replace kill) => :view
      delegate %i(register_for_updates
                  deregister_from_updates)  => :update_channel

      #
      # Components API
      #

      def_delegator :@handlers, :merge!, :add_handlers

      def create_component(name, *args)
        Rapid::Model::ComponentCreatorWrapper.new(
          Rapid::Model::ComponentCreator.new,
          method(:register)
        ).send(name, *args)
      end

      def insert_component(url, name, *args)
        insert(url, create_component(name, *args))
      end

      def replace_component(url, name, *args)
        replace(url, create_component(name, *args))
      end

      # Begins inserting multiple components into the local root at the given
      # URL
      def insert_components(url, &block)
        Rapid::Model::ComponentInserter.insert(url, self, method(:register), &block)
      end

      private

      attr_reader :authenticator
      attr_reader :update_channel
      attr_reader :view

      def register(component)
        component.register_update_channel(update_channel)
        component.register_handler(@handlers[component.handler_target])
        component
      end
    end
  end
end
