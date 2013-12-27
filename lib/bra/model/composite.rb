require 'active_support/core_ext/string/inflections'
require 'active_support/core_ext/object/try'
require 'compo'

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
    module CompositeModelObject
      extend Forwardable
      include ModelObject

      # Default implementation of driver_post
      #
      # If a resource with the requested ID exists, this will try to PUT the
      # resource inside it; otherwise, the resource is moved to the ID.
      #
      # @param id [Object] The ID to POST the resource under.
      # @param resource [Object] The resource to POST.
      #
      # @return [void]
      def driver_post(id, resource)
        existing = get_child(id)
        existing.driver_put(resource) unless existing.nil?
        resource.move_to(self, id)    if     existing.nil?
      end

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
      # @return [Object] A flat representation of this object.
      def get(privileges)
        children_to_get_representation(reachable(:get, privileges), privileges)
      end

      protected

      def reachable(action, privileges)
        can?(action, privileges) ? reachable_children(action, privileges) : {}
      end

      def reachable_children(action, privileges)
        children.select { |_, child| child.can?(action, privileges) }
      end
    end

    # A model object whose children are arranged as a hash from their IDs to
    # themselves.
    class HashModelObject < Compo::HashComposite
      include CompositeModelObject
      include Compo::Movable
      include Compo::ParentTracker

      def initialize(handler_target = nil)
        super()
        @handler_target = handler_target || default_handler_target
        remove_parent
      end

      def children_to_get_representation(children_subset, privileges)
        children_subset.transform_values { |child| child.get(privileges) }
      end
    end

    # A model object whose children form a list
    #
    # A ListModelObject stores its children in an Array, with the object IDs
    # being the numeric indices into that Array.
    class ListModelObject < Compo::ArrayComposite
      include CompositeModelObject
      include Compo::Movable
      include Compo::ParentTracker

      def initialize(handler_target = nil)
        super()
        @handler_target = handler_target || default_handler_target
        remove_parent
      end

      def children_to_get_representation(children_subset, privileges)
        children_subset.map { |child| child.get(privileges) }
      end
    end
  end
end
