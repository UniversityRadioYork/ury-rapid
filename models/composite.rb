require 'active_support/core_ext/string/inflections'
require 'active_support/core_ext/object/try'
require_relative '../exceptions'
require_relative '../utils/hash'
require_relative 'model_object'

module Bra
  module Models
    # A model object which contains children
    #
    # This should be subclassed to provide the actual child structure (hash,
    # array, et cetera).
    #
    # CompositeModelObjects should export the Enumerable interface, which
    # forwards to the children container.
    class CompositeModelObject < ModelObject
      extend Forwardable
      include Enumerable

      attr_reader :children

      # Removes a child from this model object
      #
      # @param id [ModelObject] The ID of the child to remove.
      #
      # @return [void]
      def remove_child(id)
        fail('Implementations of CompositeModelObject need to implement this.')
      end

      # Adds a child to this model object
      #
      # @param object [ModelObject] The object to add to this object's
      #   children.  The object's resource name must be unique in this object's
      #   children.
      # @param id [Object] The ID to register the child under.  Acceptable IDs
      #   depend on the underlying type of the model object.
      # 
      # @return [void]
      def add_child(object, id)
        @children[id] = object
      end

      # Attempts to find a child resource with the given partial URL
      #
      # If the resource is found, it will be yielded to the attached block;
      # otherwise, an exception will be raised.
      #
      # @param url [String] A partial URL that follows this model object's URL
      #   to form the URL of the resource to locate.  Can be nil, in which case
      #   this object is returned.
      # @param args [Array] A splat of optional arguments to provide to the
      #   block.
      #
      # @yieldparam resource [ModelObject] The resource found.
      # @yieldparam args [Array] The splat from above.
      #
      # @return [void]
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
          fail(Bra::Exceptions::MissingResourceError, url) if resource.nil?
        end

        # Once we've exhausted the tail, the resource left should be the one
        # referred to by the head.
        yield resource, *args
      end

      # GETs the resource with the given partial URL in this object's children
      #
      # @param url [String] A partial URL that follows this model object's URL
      #   to form the URL of the resource to locate.  Can be nil, in which case
      #   this object is returned.
      # @param privileges [Array] A set of privileges to check to see if the
      #   GET can be done.
      # @param mode [Symbol] See #get.
      #
      # @return [Object] the GET representation of the object if found, and nil
      #   otherwise.
      def get_url(url, privileges, mode)
        find_url(url, privileges, mode, &:resource)
      end

      # PUTs a resource with the given URL relative from this resource
      #
      # @param url [String] See #get_url.
      # @param privileges [Array] - A set of privileges to check to see if the
      #   GET can be done.
      # @param payload [Object] A payload to PUT into the child resource.  This
      #   may be a hash mapping the resource's ID to its new value, or the new
      #   value directly.
      #
      # @return [void]
      def put_url(url, privileges, payload)
        find_url(url, privileges, payload, &:put)
      end

      # As #put_url, but intended for driver usage
      #
      # @param (see #put_url)
      #
      # @return [void]
      def driver_put_url(url, payload)
        find_url(url, payload, &:driver_put)
      end

      # POSTs a resource with the given URL relative from this resource
      #
      # @param url [String] See #get_url.
      # @param privileges [Array] - A set of privileges to check to see if the
      #   GET can be done.
      # @param payload [Object] A payload to POST into the child resource.  This
      #   may be a hash mapping the resource's ID to its new value, or the new
      #   value directly.
      #
      # @return [void]
      def post_url(url, privileges, payload)
        find_url(url, privileges, payload, &:post)
      end

      # As #post_url, but intended for driver usage
      #
      # @param (see #post_url)
      #
      # @return [void]
      def driver_post_url(url, payload)
        find_url(url, payload, &:driver_post)
      end

      # DELETEs the resource with the given partial URL in this object's
      # children.
      #
      # @param (see #get_url)
      #
      # @return [void]
      def delete_url(url, privileges)
        find_url(url, privileges, &:delete)
      end

      # DELETEs the resource at the given URL relative from this resource,
      # without triggering any handlers.
      #
      # @param (see #get_url)
      #
      # @return [void]
      def driver_delete_url(url)
        find_url(url, &:driver_delete)
      end

      # Default implementation of DELETE on composite model objects
      #
      # This instructs the composite's children to delete themselves.
      #
      # @return [void]
      def delete_do
        each.to_a.each(&:delete_do)
        clear
      end
    end

    # A model object whose children are arranged as a hash from their IDs to
    # themselves.
    class HashModelObject < CompositeModelObject
      # In order to retain the same API between CompositeModelObjects, we use
      # #each_value here.
      def_delegator :@children, :each_value, :each

      def initialize
        super()
        @children = {}
      end

      # Removes a child from this model object by ID
      #
      # @param id [ModelObject] The ID of the child object to remove.
      #
      # @return [void]
      def remove_child(id)
        @children.delete(id)
      end

      # Converts this model object to a "flat" representation
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
      def get_flat(privileges = [])
        ( @children
          .select           { |_, child| child.can_get_with?(privileges) }
          .transform_values { |child|    child.get_flat(privileges)      }
        ) if can_get_with?(privileges)
      end

      # Finds the child with the given ID
      #
      # @api semipublic
      #
      # @example Find the child with ID :flub.
      #   hmo = HashModelObject.new
      #   hmo.add_child("Goose", :flub)
      #   hmo.child(:flub)
      #   #=> "Goose"
      #
      # @param id [Object] The ID of the child to find.  This may be the exact
      #   ID, a String equivalent of a Symbol ID, or an object convertable to
      #   Integer for an integral ID.
      #
      # @return [Object] The child, or nil if it was not found.
      def child(id)
        child = children[id]
        child = children[id.intern]   if child.nil? && id.respond_to?(:intern)
        child = children[Integer(id)] if child.nil?
        child
      rescue ArgumentError, TypeError
        nil
      end
    end

    # A model object whose children form a list
    #
    # A ListModelObject stores its children in an Array, with the object IDs 
    # being the numeric indices into that Array.
    class ListModelObject < CompositeModelObject
      # Implement the Enumerable API on the list's children.
      def_delegator :@children, :each

      def initialize
        super()
        @children = []
      end

      # Clears the ListModelObject
      #
      # @return [void]
      def clear
        @children = []
      end

      # Removes a child from this model object
      #
      # @param id [Fixnum] The index of the child object to remove.
      #
      # @return [void]
      def remove_child(id)
        @children.delete_at(id)
      end

      # Converts this model object to a "flat" representation
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
      def get_flat(privileges = [])
        ( @children
          .select { |child| child.can_get_with?(privileges) }
          .map    { |child| child.get_flat(privileges)      }
        ) if can_get_with?(privileges)
      end

      # Finds the child with the given ID
      #
      # @api semipublic
      #
      # @example Find the child with ID 3.
      #   lmo = ListModelObject.new
      #   lmo.add_child("Spruce", 3)
      #   lmo.child(3)
      #   #=> "Spruce"
      #
      # @param id [Object] The ID of the child to find.  This may be the exact
      #   ID or an object convertable to Integer.
      #
      # @return [Object] The child, or nil if it was not found.
      def child(id)
        children[Integer(id)]
      rescue ArgumentError, TypeError
        nil
      end
    end
  end
end
