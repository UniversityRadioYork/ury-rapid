require 'active_support/core_ext/string/inflections'
require 'active_support/core_ext/object/try'

module Bra
  module Models
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
    class ModelObject
      # Public: Allows access to this model object's current ID.
      attr_reader :id

      # Public: Allows read access to the object's children.
      attr_reader :children

      # Public: Allows read access to the object's parent.
      attr_reader :parent

      def initialize
        @parent = nil
        @id = nil
        @handler = nil
      end

      # Registers a handler to be used when this object is modified
      #
      # @param handler [Object] A handler object.  This may contain the methods
      #   put and delete, which handle PUTs and DELETEs respectively.  These
      #   methods shall return true if the model should update itself, and
      #   false if the model should wait until instructed by the driver.
      #
      # @return [ModelObject] This object, for method chaining purposes.
      def register_handler(handler)
        @handler = handler
        self
      end

      # Fails if an operation cannot proceed on this model object
      def fail_if_cannot(operation, privilege_set)
        privilege_set.require(handler_target, operation)
      end

      # Checks whether an operation can proceed on this model object
      def can?(operation, privilege_set)
        privilege_set.has?(handler_target, operation)
      end

      # GETs this model object
      #
      # A GET is the retrieval of a flattened representation of a model object.
      # See #get_flat (defined differently for different model objects) for
      # information on what constitutes a flattened representation.
      #
      # @param privileges [PrivilegeSet] The set of privileges the client has.
      # @param mode [Symbol] Either :wrap, in which case the result will be
      #   wrapped in a hash mapping the object's ID to the flattened
      #   representation, or :nowrap, in which case only the flattened value is
      #   returned.  By default, :wrap is used.
      #
      # @return [Object] A flat representation of this object.
      def get(privileges, mode = :wrap)
        fail_if_cannot(:get, privileges)
        wrap(get_flat(privileges), mode)
      end

      # Wraps a GET response according to its wrap mode.
      #
      # @param value [Object] The value to wrap (or not).
      # @param mode [Symbol] Either :wrap, in which case the result will be
      #   wrapped in a hash mapping the object's ID to the flattened
      #   representation, or :nowrap, in which case only the flattened value is
      #   returned.  By default, :wrap is used.
      #
      # @return [Object] The (potentially) wrapped value.
      def wrap(value, mode)
        # TODO(mattbw): Flatten non-plain-old-data values?
        case mode
        when :wrap
          { id => value }
        when :nowrap
          value
        else
          fail("Unknown get_flat mode: #{mode}")
        end
      end

      # POSTs a resource inside this model object, using the post handler
      #
      # The resource can be a direct instance of this object, or a hash mapping
      # this object's ID to one.
      def post(payload)
        payload_action(:post, payload)
      end

      # PUTs a resource into this model object, using the put handler.
      #
      # The resource can be a direct instance of this object, or a hash mapping
      # this object's ID to one.
      def put(payload)
        payload_action(:put, payload)
      end

      # DELETEs this model object, using the delete handler.
      def delete(privileges)
        fail_if_cannot(:delete, privileges)
        @handler.delete(self)
      end

      # PUTs a resource to this model object, without using the put handler.
      #
      # This is a stub; any concrete model objects must override it.
      #
      # Consider using driver_put for code updating the model from the driver.
      def put_do(_)
        fail("put_do needs overriding for object #{id}, class #{self.class}.")
      end

      # DELETEs this model object, without using the delete handler.
      #
      # This is a stub; any concrete model objects must override it.
      #
      # Consider using driver_delete for code updating the model from the
      # driver.
      def delete_do
        raise "delete_do must be overridden for model object #{id}."
      end

      # Moves this model object to a new parent with a new ID.
      #
      # @param new_parent [ModelObject] The new parent for this object (can be
      #   nil).
      # @param new_id [Object]  The new ID under which the object will exist in
      #   the parent.
      #
      # @return [ModelObject] This object, for method chaining.
      def move_to(new_parent, new_id)
        @parent.remove_child(self) unless @parent.nil?
        @parent = new_parent
        @parent.add_child(self, new_id) unless @parent.nil?
        @id = new_id

        self
      end

      # The canonical URL of this model object.
      #
      # This is effectively the result of postfixing this object's ID to the
      # canonical URL of its parent.
      #
      # @return [String] The URL.
      def url
        [parent_url, id].join('/')
      end

      # The ID of this model object's parent.
      # @return [String] The parent's ID.
      def parent_id
        @parent.id
      end

      # The canonical URL of this model object's parent.
      # @return [String] The parent's URL.
      def parent_url
        @parent.url
      end

      # The name under which this object's handlers are defined
      #
      # Usually this will be class name, stripped of its module prefix and
      # converted to a lowercase_underscore symbol.  This may be overridden for
      # objects with the same class but different handlers (for example, 
      # variables).
      #
      # @api semipublic
      #
      # @example Get the handler target.
      #   ModelObject.new.handler_target
      #   #=> model_object
      #
      # @return [Symbol] The handler target.
      def handler_target
        self.class.name.demodulize.underscore.intern
      end

      # Returns the default ID to give to POST payloads
      def default_id
        nil
      end

      private

      def payload_action(action, payload)
        fail_if_cannot(action, payload.privilege_set)
        @handler.send(action, self, payload)
      end
    end

    # A model object that does not have children.
    class SingleModelObject < ModelObject
      def children
        nil
      end

      # Responds to any request for a child with nil.
      #
      # This is because SingleModelObject has no children.
      #
      # @return [NilClass] nil.
      def child(_)
        nil
      end

      # Converts this model object to a "flat" representation.
      #
      # Flat representations contain only primitive objects (integers, strings,
      # etc.) and lists and hashes.
      #
      # For a SingleModelObject, the default implementation of this is to call
      # a no-arguments method 'flat' which can be overridden by subclasses.
      #
      # @param privileges [Array] An array of GET privileges the caller has.
      #   May be nil, in which case no privilege checking is done.
      #
      # @return [Object] A flat representation of this object.
      def get_flat(privileges = [])
        flat if can?(:get, privileges)
      end
    end
  end
end
