require 'active_support/core_ext/string/inflections'
require 'active_support/core_ext/object/try'

require 'bra/common/exceptions'
require 'bra/common/hash'
require 'bra/model/model_object'

module Bra
  module Model
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

      # Returns whether this object can have children.
      #
      # CompositeModelObjects can have children.
      #
      # @return [Boolean] true.
      def can_have_children?
        true
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

        until tail.nil? || tail.empty?
          # We need to keep traversing down, as we've still got a tail.
          head, tail = tail.split('/', 2)
          resource = resource.child(head)
          fail(Bra::Common:Exceptions::MissingResource, url) if resource.nil?
        end

        # Once we've exhausted the tail, the resource left should be the one
        # referred to by the head.
        yield resource, *args
      end

      %w{put post delete}.each do |action|
        define_method("driver_#{action}_url") do |url, *args|
          find_url(url) { |resource| resource.send("driver_#{action}", *args) }
        end
      end

      # Default implementation of DELETE on composite model objects
      #
      # This instructs the composite's children to delete themselves.
      #
      # @return [void]
      def driver_delete
        each.to_a.each(&:driver_delete)
        clear
      end

      # Default implementation of driver_post.
      #
      # If a resource with the requested ID exists, this will try to PUT the
      # resource inside it; otherwise, the resource is moved to the ID.
      #
      # @param id [Object] The ID to POST the resource under.
      # @param resource [Object] The resource to POST.
      #
      # @return [void]
      def driver_post(id, resource)
        existing = child(id)
        existing.driver_put(resource) unless existing.nil?
        resource.move_to(self, id)    if     existing.nil?
      end
    end

    # A model object whose children are arranged as a hash from their IDs to
    # themselves.
    class HashModelObject < CompositeModelObject
      extend Forwardable

      # In order to retain the same API between CompositeModelObjects, we use
      # #each_value here.
      def_delegator :@children, :each_value, :each
      def_delegator :@children, :[]=, :add_child
      def_delegator :@children, :delete, :remove_child

      def initialize(*args)
        super(*args)
        @children = {}
      end

      alias_method :child_hash, :children

      # GETs this model object as a 'flat' representation
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
      def get(privileges = [])
        ( @children
          .select           { |_, child| child.can?(:get, privileges) }
          .transform_values { |child|    child.get(privileges)        }
        ) if can?(:get, privileges)
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

      def id_function(object)
        # Assuming two ModelObjects == if and only if equal?.
        proc { children.key(object) }
      end
    end

    # A model object whose children form a list
    #
    # A ListModelObject stores its children in an Array, with the object IDs
    # being the numeric indices into that Array.
    class ListModelObject < CompositeModelObject
      extend Forwardable

      # Implement the Enumerable API on the list's children.
      def_delegator :@children, :each
      def_delegator :@children, :size

      def initialize(*args)
        super(*args)
        @children = []
      end

      # Gets this object's children, as a hash
      def child_hash
        Hash[*@children.each_with_index.to_a]
      end

      # Clears the ListModelObject
      #
      # @return [void]
      def clear
        @children = []
      end

      def_delegator :@children, :insert, :add_child
      def_delegator :@children, :delete_at, :remove_child

      # GETs this model object as a 'flat' representation
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
      def get(privileges = [])
        ( @children
          .select { |child| child.can?(:get, privileges) }
          .map    { |child| child.get(privileges)        }
        ) if can?(:get, privileges)
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

      def id_function(object)
        proc { children.index { |member| member.equal?(object) } }
      end
    end
  end
end
