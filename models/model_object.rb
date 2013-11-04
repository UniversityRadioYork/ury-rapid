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

      # Tests if the given privileges are sufficient for GETting this
      # object.
      #
      # @param candidates [Array] A set of privileges to check for
      #   authorisation.  This can be nil, in which case the check will always
      #   succeed.  In order to fail all checks, pass the empty list [].
      # @return [Boolean] true if the privileges are sufficient; false
      #   otherwise.
      def can_get_with?(candidates)
        check_privilege(candidates, get_privileges)
      end

      # Tests if the given privileges are sufficient for PUTting this
      # object.
      #
      # @param (see #can_get_with?)
      # @return (see #can_get_with?)
      def can_put_with?(candidates)
        check_privilege(candidates, put_privileges)
      end

      # Tests if the given privileges are sufficient for DELETEing this
      # object.
      #
      # @param (see #can_get_with?)
      # @return (see #can_get_with?)
      def can_delete_with?(candidates)
        check_privilege(candidates, delete_privileges)
      end

      # Checks a set of candidate privileges against another set to see if they
      # match.
      #
      # @param candidates [Array] The candidate privileges.  If nil, treat as
      #   if all privileges are candidate privileges.
      # @param requisites [Array] The required privileges.  If nil, reject all
      #   candidates values except nil.
      # @return (see #can_get_with?)
      def check_privilege(candidates, requisites)
        if candidates.nil?
          true
        elsif requisites.nil?
          false
        else
          # Check the set intersection (the candidates that are also requisites)
          # contains every requisite.
          (candidates & requisites) == requisites
        end
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

      # GETs this model object.
      # 
      # A GET is the retrieval of a flattened representation of a model object.
      # See #get_flat (defined differently for different model objects) for
      # information on what constitutes a flattened representation.
      #
      # @param privileges [Array] An array of GET privileges the caller has.
      #   May be nil, in which case no privilege checking is done.
      #
      # @param mode [Symbol] Either :wrap, in which case the result will be
      #   wrapped in a hash mapping the object's ID to the flattened
      #   representation, or :nowrap, in which case only the flattened value is
      #   returned.  By default, :wrap is used.
      #
      # @return [Object] A flat representation of this object.
      def get(privileges=[], mode=:wrap)
        if can_get_with?(privileges)
          value = get_flat(privileges)
          # TODO: Flatten non-plain-old-data values.
          case mode
          when :wrap
            { id => value }
          when :nowrap
            value
          else
            fail("Unknown get_flat mode: #{mode}")
          end
        end
      end

      # PUTs a resource into this model object, using the put handler.
      #
      # The resource can be a direct instance of this object, or a hash mapping
      # this object's ID to one.
      def put(privileges, resource)
        fail("Insufficient privileges.") unless can_put_with?(privileges) 

        # Remove any outer hash.
        value = resource[id] if resource.is_a?(Hash)
        value = resource unless resource.is_a?(Hash)

        # Only update the model if the handler allows us to with this given
        # value.
        put_do(value) if @put_handler.call(self, value)
      end

      # DELETEs this model object, using the delete handler.
      def delete(privileges)
        fail("Insufficient privileges.") unless can_delete_with?(privileges) 

        # Again, only update the model if the handler allows us to.
        delete_do if @delete_handler.call(self)
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
      # @param url [String] A partial URL that follows this model object's URL to form
      #   the URL of the resource to locate.  Can be nil, in which case this
      #   object is returned.
      # @param privileges [Array] A set of privileges to check to see if the
      #   GET can be done.
      # @param mode [Symbol] See #get.
      #
      # @return the GET representation of the object if found, and nil
      #   otherwise.
      def get_url(url, privileges, mode)
        find_url(url, privileges, mode, &:resource)
      end

      # PUTs the resource with the given partial URL in this object's children.
      #
      # @param url [String] See #get_url.
      # @param privileges [Array] - A set of privileges to check to see if the
      #   GET can be done.
      # @param payload [Object] A payload to PUT into the child resource.  This
      #   may be a hash mapping the resource's ID to its new value, or the new
      #   value directly.
      def put_url(url, privileges, payload)
        find_url(url, privileges, payload, &:put)
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
      def delete_url(url, privileges)
        find_url(url, privileges, &:delete)
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

      # Converts this model object to a "flat" representation.
      #
      # Flat representations contain only primitive objects (integers, strings,
      # etc.) and lists and hashes.
      #
      # In a flat representation, children requiring privileges the caller does
      # not have are hidden.
      #
      # @param privileges [Array] An array of GET privileges the caller has.
      #   May be nil, in which case no privilege checking is done.
      #
      # @return [Hash] A flat representation of this object.
      def get_flat(privileges=[]) 
        ( @children
          .select           { |_, child| child.can_get_with?(privileges) }
          .transform_values { |child|    child.get_flat     (privileges) }
        ) if can_get_with?(privileges)
      end

      def child(target_name)
        child = children[target_name]
        child = children[target_name.intern]   if child.nil?
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

      # Converts this model object to a "flat" representation.
      #
      # Flat representations contain only primitive objects (integers, strings,
      # etc.) and lists and hashes.
      #
      # In a flat representation, children requiring privileges the caller does
      # not have are hidden.
      #
      # @param privileges [Array] An array of GET privileges the caller has.
      #   May be nil, in which case no privilege checking is done.
      #
      # @return [Array] A flat representation of this object.
      def get_flat(privileges=[]) 
        ( @children
          .select { |child| child.can_get_with?(privileges) }
          .map    { |child| child.get_flat     (privileges) }
        ) if can_get_with?(privileges)
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
      def get_flat(privileges=[]) 
        flat if can_get_with?(privileges)
      end
    end
  end
end
