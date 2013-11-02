require 'active_support/core_ext/string/inflections'
require_relative '../utils/hash'

module Bra
  module Models
    # Internal: An object in the BRA model.
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

      ##
      # GET this resource.
      #
      # Returns a hash mapping this object's ID to the object itself.
      def get
        { id => self }
      end

      ##
      # PUT a resource into this model object, using the put handler.
      #
      # The resource can be a direct instance of this object, or a hash mapping
      # this object's ID to one.
      def put(new_body)
        # Remove any outer hash.
        value = new_body[id]
        value ||= new_body

        # Only update the model if the handler allows us to with this given
        # value.
        put_do(value) if @put_handler.call(self, value)
      end

      ##
      # DELETE this model object, using the delete handler.
      def delete
        # Again, only update the model if the handler allows us to.
        delete_do if @delete_handler.call
      end

      ##
      # PUT a resource to this model object, without using the put handler.
      #
      # This is a stub; any concrete model objects must override it.
      #
      # Consider using driver_put for code updating the model from the driver.
      def put_do(_)
        raise 'put_do must be overridden in model objects.'
      end

      ##
      # DELETE this model object, without using the delete  handler.
      #
      # This is a stub; any concrete model objects must override it.
      #
      # Consider using driver_put for code updating the model from the driver.
      def delete_do
        raise 'delete_do must be overridden in model objects.'
      end

      # The driver_XYZ methods allow the driver to perform modifications to the
      # model using the same verbs as the server without triggering the usual
      # handlers.  They are implemented using the _do methods.
      alias_method :driver_put, :put_do
      alias_method :driver_delete, :delete_do

      # Public: Moves this model object to a new parent with a new ID.
      #
      # new_parent - The new parent for this object (can be nil).
      # new_id     - The new ID under which the object will exist in the
      #              parent.
      #
      # Returns this object, for method chaining.
      def move_to(new_parent, new_id)
        @parent.remove_child(self) unless @parent.nil?
        @parent = new_parent
        @parent.add_child(self, new_id) unless @parent.nil?
        @id = new_id

        self
      end

      # Public: Converts a model object to compact JSON.
      #
      # This expects a to_jsonable method to be defined.
      #
      # Returns the JSON representation of the model object.
      def to_json(*args)
        to_jsonable.to_json(*args)
      end

      def url
        [parent_url, id].join('/')
      end

      def parent_id
        @parent.id
      end

      def parent_url
        @parent.url
      end

      # Public: Returns this class's internal name, used for things such as
      # templates and JSON attributes.
      #
      # This is different from the resource name in that it is the same for
      # all objects of the same category.
      #
      # Returns the internal name as a symbol.
      def internal_name
        self.class.name.demodulize.underscore.intern
      end
    end

    # Public: Class for model objects that contain children.
    #
    # This should be subclassed to provide the actual child structure (hash,
    # array, et cetera).
    class CompositeModelObject < ModelObject
      attr_reader :children

      # Public: Removes a child from this model object.
      #
      # object - The object to remove from this object's children.
      #
      def remove_child(object)
        @children.delete(object.resource_name)
      end

      # Public: Adds a child to this model object.
      #
      # object - The object to add to this object's children.  The object's
      #          resource name must be unique in this object's children.
      # id     - The ID to register the child under.  Acceptable IDs depend
      #          on the underlying type of the model object.
      #
      # Returns nothing.
      def add_child(object, id)
        @children[id] = object
      end

      # Public: Attempts to find the resource with the given partial URI in
      # this object's children.
      #
      # resource - A partial URI that follows this model object's URI to form
      #            the URI of the resource to locate.  Can be nil, in which
      #            case this object is returned.
      # args     - Optional arguments to provide to the block.
      # block    - An optional block to yield the resource to.
      #
      # Returns as below if no block is provided, or the result of the block
      #   otherwise.
      # Yields the object if found, and nil otherwise.
      def find_url(resource, *args, &block)
        # Without a block, just pass the resource through.
        block ||= ->(x){ x }

        if resource.nil?
          block.call(self, *args)
        else
          head, tail = resource.split('/', 2)
          child(head).try { |next_level| next_level.find_url(tail) }
        end
      end

      # Public: GETs the resource with the given partial URI in this object's
      # children.
      #
      # resource - A partial URI that follows this model object's URI to form
      #            the URI of the resource to locate.  Can be nil, in which
      #            case this object is returned.
      #
      # Returns the GET representation of the object if found, and nil
      #   otherwise.
      def get_url(resource)
        find_url(resource, &:get)
      end

      ##
      # DELETEs the resource at the given URL relative from this resource,
      # without triggering any handlers.
      # Public: PUTs the resource with the given partial URI in this object's
      # children.
      #
      # resource - A partial URI that follows this model object's URI to form
      #            the URI of the resource to locate.  Can be nil, in which
      #            case this object is returned.
      # payload  - A hash containing the payload to PUT into the child
      #            resource.
      #
      # Returns nothing.
      def put_url(resource, payload)
        find_url(resource, payload, &put)
      end

      ##
      # PUTs a payload into the resource at the given URL relative from this
      # resource, without triggering any handlers.
      def driver_put_url(resource, payload)
        find_url(resource, payload, &driver_put)
      end

      # Public: PUTs the resource with the given partial URI in this object's
      # children, from the perspective of the playout system.
      #
      # resource - A partial URI that follows this model object's URI to form
      #            the URI of the resource to locate.  Can be nil, in which
      #            case this object is returned.
      # payload  - A hash containing the payload to PUT into the child
      #            resource.
      #
      # Returns nothing.
      def driver_put_url(resource, payload)
        find_url(resource, payload, &:driver_put)
      end

      # Public: DELETEs the resource with the given partial URI in this
      # object's children.
      #
      # url - A partial URI that follows this model object's URI to form
      #       the URI of the resource to locate.  Can be nil, in which
      #       case this object is returned.
      #
      # Returns nothing.
      def delete_url(url)
        find_url(resource, &:delete)
      end

      ##
      # DELETEs the resource at the given URL relative from this resource,
      # without triggering any handlers.
      def driver_delete_url(url)
        find_url(resource, &:driver_delete)
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

    ##
    # A model object that does not have children.
    class SingleModelObject < ModelObject
      def children
        nil
      end

      def child(_)
        nil
      end

      # Public: Attempts to find the resource with the given partial URI in
      # this object's (nonexistent) children.
      #
      # resource - A partial URI that follows this model object's URI to form
      #            the URI of the resource to locate.  Can be nil, in which
      #            case this object is returned.
      #
      # Returns the object if the resource matches this one, and nil otherwise.
      def find_url(resource)
        resource.nil? ? self : nil
      end
    end
  end
end
