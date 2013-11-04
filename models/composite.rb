require 'active_support/core_ext/string/inflections'
require 'active_support/core_ext/object/try'
require_relative '../utils/hash'
require_relative 'model_object'

module Bra
  module Models
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
      # @param args [Array] A splat of optional arguments to provide to the
      #   block.
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
      # @param url [String] A partial URL that follows this model object's URL
      #   to form the URL of the resource to locate.  Can be nil, in which case
      #   this object is returned.
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
      def get_flat(privileges = [])
        ( @children
          .select           { |_, child| child.can_get_with?(privileges) }
          .transform_values { |child|    child.get_flat(privileges)      }
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
      def get_flat(privileges = [])
        ( @children
          .select { |child| child.can_get_with?(privileges) }
          .map    { |child| child.get_flat(privileges)      }
        ) if can_get_with?(privileges)
      end

      def child(target_name)
        children[Integer(target_name)]
      rescue ArgumentError, TypeError
        nil
      end
    end
  end
end
