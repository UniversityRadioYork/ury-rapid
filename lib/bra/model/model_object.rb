require 'active_support/core_ext/string/inflections'
require 'active_support/core_ext/object/try'

require 'kankri'
require 'bra/model/update_channel'

module Bra
  module Model
    # An object in the bra playout system model.
    #
    # ModelObjects are composable entities, each assigned an ID by its parent,
    # that form a model tree traversable by relative URLs.
    #
    # Each ModelObject implements an interface based on the HTTP verbs GET,
    # PUT, POST and DELETE, both directly and via URL (for accessing objects
    # further down in the tree from the target).
    #
    # With the exception of GET, each verb is further subdivided into a form
    # that can trigger driver handlers to translate model change requests into
    # playout server actions, and a 'driver' form that bypasses these handlers.
    module ModelObject
      extend Forwardable
      include Kankri::PrivilegeSubject
      include Updatable

      def initialize(handler_target = nil, *args)
        super(*args)
        @handler_target = handler_target || default_handler_target
        @update_channel = NoUpdateChannel.new
      end

      # Registers a handler to be called when this object is modified
      #
      # @param handler [Object] A handler object.  This may contain the methods
      #   put and delete, which handle PUTs and DELETEs respectively.  These
      #   methods shall return true if the model should update itself, and
      #   false if the model should wait until instructed by the driver.
      #
      # @return [self]
      def register_handler(handler)
        @handler = handler
        self
      end

      # GETs this model object
      #
      # A GET is the retrieval of a flattened representation of a model object.
      # See #flat (defined differently for different model objects) for
      # information on what constitutes a flattened representation.
      #
      # @param privileges [PrivilegeSet] The set of privileges the client has.
      #
      # @return [Object] A flat representation of this object.
      def get(privileges)
        fail_if_cannot(:get, privileges)
        flat
      end

      # The flat representation of this model object
      # 
      # Usually, this is just the mapping of #flat to this object's children.
      # Objects should override this if they are not simply containers of other
      # children.
      def flat
        children.transform_values(&:flat)
      end

      # Takes a PUT payload intended for this object and POSTs it to its parent
      def post_to_parent(payload)
        parent.post(payload)
      end

      %i{put post delete}.each do |action|
        # Define payload-based server methods.

        define_method(action) do |payload|
          fail_if_cannot(action, payload.privilege_set)
          @handler.call(action, self, payload)
        end

        # Define error-raising stubs for the driver modifiers.
        define_method("driver_#{action}") do |*|
          fail(Bra::Common::Exceptions::NotSupportedByBra)
        end
      end

      # Default implementation of driver_put
      #
      # This will just POST into the parent.
      #
      # @param resource [Object] The resource to PUT.
      #
      # @return [void]
      def driver_put(resource)
        parent.driver_post(id, resource)
      end

      # Default implementation of driver_post
      #
      # This will, by default, move the incoming resource to this object
      # under the given ID, replacing any existing resource.
      #
      # @param id [Object] The ID to POST the resource under.
      # @param resource [Object] The resource to POST.
      #
      # @return [void]
      def driver_post(id, resource)
        unless resource.nil?
          resource.move_to(self, id)
          resource.notify_update
        end
      end

      # Default implementation of DELETE on model objects
      #
      # This instructs the object's children to delete themselves.  Since
      # #each is a no-op on Compo::Branches::Leaf, this is safe to use with any model
      # object.
      #
      # @return [void]
      def driver_delete
        each { |_, value| value.driver_delete }
      end

      def_delegator :@parent, :id, :parent_id

      # The identifier used to find handlers and privileges for this object
      #
      # When @handler_target is nil (the default), this is the class name,
      # stripped of its module and converted  to a lowercase_underscored
      # Symbol.  If @handler_target is specified, however, that will be
      # returned instead.
      #
      # @api public
      # @example  Get the default handler target.
      #   ModelObject.new.handler_target
      #   #=> :model_object
      # @example  Get a specified handler target.
      #   ModelObject.new(:widget).handler_target
      #   #=> :widget
      #
      # @return [Symbol]  The handler target for this object.
      attr_reader :handler_target
      alias_method :privilege_key, :handler_target

      # The default handler target for this class
      #
      # When @handler_target is nil (the default), this is the class name,
      # stripped of its module and converted  to a lowercase_underscored
      # Symbol.  If @handler_target is specified, however, that will be
      # returned instead.
      #
      # @api public
      # @example  Get the default handler target.
      #   ModelObject.new.handler_target
      #   #=> :model_object
      # @example  Get a specified handler target.
      #   ModelObject.new(:widget).handler_target
      #   #=> :widget
      #
      # @return [Symbol]  The handler target for this object.
      def default_handler_target
        self.class.name.demodulize.underscore.intern
      end

      # Returns the default ID to give to POST payloads
      def default_id
        nil
      end
    end
  end
end
