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
        short_name ||= name

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

      # Public: Perform a GET on this model object.
      #
      # Returns a hash mapping this object's ID to the object itself.
      # of its value.
      def get
        { id => self }
      end

      # Public: Perform a PUT on this model object.
      #
      # new_body - A hash mapping this object's ID to its new value.
      #
      # Returns nothing.
      def put(new_body)
        new_body[id].try do |value|
					put_do(value) if @put_handler.call(self, value)
				end
      end

      # Public: Perform a DELETE on this model object.
      #
      # Returns nothing.
      def delete
        delete_do if @delete_handler.call
      end

      def name
        @id
      end

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

      def parent_name
        @parent.name
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
      def find_resource(resource, *args, &block)
        block ||= ->(resource){ resource }

        if resource.nil?
          block.call(self, *args)
        else
          head, tail = resource.split('/', 2)
          child(head).try { |next_level| next_level.find_resource(tail) }
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
      def get_resource(resource)
        find_resource(resource, &:get)
      end

      # Public: PUTs the resource with the given partial URI in this object's
      # children.
      #
      # resource - A partial URI that follows this model object's URI to form
      #            the URI of the resource to locate.  Can be nil, in which
      #            case this object is returned.
      # payload  - A hash containing the payload to PUT into the child
      #            resource.
      # raw      - If true, skip the PUT handler for this resource.  This is
      #            useful when PUTting from the playout system controller, and
      #            not so useful when PUTting from the client.
      #
      # Returns nothing.
      def put_resource(resource, payload, raw)
        find_resource(resource, payload, &(raw ? :put_do : :put))
      end

      # Public: DELETEs the resource with the given partial URI in this object's
      # children.
      #
      # resource - A partial URI that follows this model object's URI to form
      #            the URI of the resource to locate.  Can be nil, in which
      #            case this object is returned.
      # raw      - If true, skip the DELETE handler for this resource.  This is
      #            useful when deleting from the playout system controller, and
      #            not so useful when deleting from the client.
      #
      # Returns nothing.
      def delete_resource(resource, raw)
        find_resource(resource, &(raw ? :delete_do : :delete))
      end

    end

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

    # Class for model objects that do not contain children.
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
      def find_resource(resource)
        resource.nil? ? self : nil
      end
    end
  end
end
