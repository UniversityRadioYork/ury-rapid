require 'active_support/core_ext/string/inflections'
require 'active_support/core_ext/object/try'
require_relative '../utils/hash'

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

        @put_handler = nil
        @delete_handler = nil
      end

      # Internal: Registers a handler to be called when this object is PUT.
      #
      # block - A proc that will be executed before the model is updated.
      #         It should take one argument, the new value of this object in
      #         plain-old-data format, and return True if the model should
      #         update itself (and False otherwise).
      #
      # Returns this object, for method chaining purposes.
      def register_put_handler(block)
        @put_handler = block
        self
      end

      # Internal: Registers a handler to be called when this object is DELETEd.
      #
      # block - A proc that will be executed before the model is updated.
      #         It should take no arguments and return True if the model should
      #         update itself (and False otherwise).
      #
      # Returns this object, for method chaining purposes.
      def register_delete_handler(block)
        @delete_handler = block
        self
      end

      # GETs this resource.
      #
      # Returns a hash mapping this object's ID to the object itself.
      def get
        { id => self }
      end

      # PUTs a resource into this model object, using the put handler.
      #
      # The resource can be a direct instance of this object, or a hash mapping
      # this object's ID to one.
      def put(resource)
        # Remove any outer hash.
        value = resource[id] if resource.is_a?(Hash)
        value = resource unless resource.is_a?(Hash)

        # Only update the model if the handler allows us to with this given
        # value.
        put_do(value) if @put_handler.call(self, value)
      end

      # DELETEs this model object, using the delete handler.
      def delete
        # Again, only update the model if the handler allows us to.
        delete_do if @delete_handler.call
      end

      # PUTs a resource to this model object, without using the put handler.
      #
      # This is a stub; any concrete model objects must override it.
      #
      # Consider using driver_put for code updating the model from the driver.
      def put_do(_)
        fail("put_do needs overriding for object #{id}, class #{self.class}.")
      end

      # DELETEs this model object, without using the delete  handler.
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

      # Converts a model object to compact JSON.
      #
      # This expects a to_jsonable method to be defined.
      #
      # @param args [Array] A splat of args to send to the inner to_json calls.
      #
      # @return [String] The JSON representation of the model object.
      def to_json(*args)
        to_jsonable.to_json(*args)
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

      # Returns this class's internal name, used for things such as templates
      # and JSON attributes.
      #
      # This is different from the resource name in that it is the same for
      # all objects of the same category.
      #
      # @return [Symbol] The internal name.
      def internal_name
        self.class.name.demodulize.underscore.intern
      end
    end

    # A model object which contains children.
    #
    # This should be subclassed to provide the actual child structure (hash,
    # array, et cetera).
    class CompositeModelObject < ModelObject
      attr_reader :children

      # Removes a child from this model object.
      #
      # @param object [ModelObject] The object to remove from this object's
      #   children.
      #
      def remove_child(object)
        @children.delete(object.id)
      end

      # Adds a child to this model object.
      #
      # @param object [ModelObject] The object to add to this object's
      #   children.  The object's resource name must be unique in this object's
      #   children.
      # @param id [Object] The ID to register the child under.  Acceptable IDs
      #   depend on the underlying type of the model object.
      def add_child(object, id)
        @children[id] = object
      end

      # Attempts to find the resource with the given partial URL in this
      # object's children.
      #
      # If the resource is found, it will be yielded to the attached block;
      # otherwise, an exception will be raised.
      #
      # @param url [String] A partial URL that follows this model object's URL
      #   to form the URL of the resource to locate.  Can be nil, in which case
      #   this object is returned.
      # @param args [Array] A splat of optional arguments to provide to the block.
      #
      # @yieldparam resource [ModelObject] The resource found.
      # @yieldparam args [Array] The splat from above.
      def find_url(url, *args)
        # We're traversing down the URL by repeatedly splitting it into its
        # head (part before the next /) and tail (part after).  While we still
        # have a tail, then the URL still needs walking down.
        head, tail = nil, url.chomp('/')

        resource = self

        while tail
          # We need to keep traversing down, as we've still got a tail.
          head, tail = tail.split('/', 2)
          resource = resource.child(head)
          fail("#{resource.id} has no child #{new_head}.") if resource.nil?
        end

        # Once we've exhausted the tail, the resource left should be the one
        # referred to by the head.
        yield resource, *args
      end

      # GETs the resource with the given partial URL in this object's children.
      #
      # @param url [String]resource - A partial URL that follows this model object's URL to form
      #            the URL of the resource to locate.  Can be nil, in which
      #            case this object is returned.
      #
      # Returns the GET representation of the object if found, and nil
      #   otherwise.
      def get_url(url)
        find_url(url, &:get)
      end

      # PUTs the resource with the given partial URL in this object's children.
      #
      # @param url [String] See #get_url.
      # @param payload [Object] A payload to PUT into the child resource.  This
      #   may be a hash mapping the resource's ID to its new value, or the new
      #   value directly.
      def put_url(url, payload)
        find_url(url, payload, &:put)
      end

      # PUTs a payload into the resource at the given URL relative from this
      # resource, without triggering any handlers.
      #
      # @param (see #put_url)
      def driver_put_url(url, payload)
        find_url(url, payload, &:driver_put)
      end

      # DELETEs the resource with the given partial URL in this object's
      # children.
      #
      # @param (see #get_url)
      def delete_url(url)
        find_url(url, &:delete)
      end

      # DELETEs the resource at the given URL relative from this resource,
      # without triggering any handlers.
      #
      # @param (see #get_url)
      def driver_delete_url(url)
        find_url(url, &:driver_delete)
      end
    end

    ##
    # A model object whose children are arranged as a hash from their IDs to
    # themselves.
    class HashModelObject < CompositeModelObject
      def initialize
        super()
        @children = {}
      end

      # Public: Converts a model object to a format that can be rendered to
      # JSON.
      #
      # Returns a representation of the model object that can be converted to
      # JSON.
      def to_jsonable
        @children.transform_values { |child| child.to_jsonable }
      end

      def child(target_name)
        child = children[target_name]
        child = children[target_name.intern] if child.nil?
        child = children[Integer(target_name)] if child.nil?
        child
      rescue ArgumentError, TypeError
        nil
      end
    end

    ##
    # A model object whose children form a list.
    class ListModelObject < CompositeModelObject
      def initialize
        super()
        @children = []
      end

      # Public: Converts a model object to a format that can be rendered to
      # JSON.
      #
      # Unless overridden, this expects a to_hash method to be defined.
      #
      # Returns a representation of the model object that can be converted to
      # JSON.
      def to_jsonable
        children.map { |child| child.to_jsonable }
      end

      def child(target_name)
        children[Integer(target_name)]
      rescue ArgumentError, TypeError
        nil
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
    end
  end
end
