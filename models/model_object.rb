require 'active_support/core_ext/string/inflections'

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
      end

      def name
        @id
      end

      def move_to(new_parent, new_id)
        @parent.remove_child(self) unless @parent.nil?
        @parent = new_parent
        @parent.add_child(self, new_id) unless @parent.nil?
        @id = new_id
      end

      def resource_name
        @id
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
        [parent_url, resource_name].join('/')
      end

      def parent_name
        @parent.name
      end

      def parent_url
        @parent.url
      end

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
      #
      # Returns the object if found, and nil otherwise.
      def find_resource(resource)
        if resource.nil?
          self
        else
          head, tail = resource.split('/', 2)
          next_level = child(head)
          next_level.nil? ? nil : next_level.find_resource(tail)
        end
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

    class HashModelObject < ModelObject
      attr_reader :children

      def initialize
        super()
        @children = {}
      end

      # Public: Converts a model object to a format that can be rendered to
      # JSON.
      #
      # Unless overridden, this expects a to_hash method to be defined.
      #
      # Returns a representation of the model object that can be converted to
      # JSON.
      def to_jsonable
        @children.each_with_object({}) do |(key, value), hash|
          hash[key] = value.to_jsonable
        end
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

    class ListModelObject < ModelObject
      attr_reader :children

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
  end
end
