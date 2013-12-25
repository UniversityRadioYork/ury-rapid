require 'active_support/core_ext/string/inflections'
require 'active_support/core_ext/object/try'

require 'kankri'
require 'bra/model/update_channel'

module Bra
  module Model
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
      extend Forwardable
      include Kankri::PrivilegeSubject
      include Updatable

      attr_reader :parent

      # Initialises the ModelObject
      #
      # @api public
      # @example  Initialises a ModelObject with the default handler target.
      #   ModelObject.new
      # @example  Initialises a ModelObject with a specific handler target.
      #   ModelObject.new(:specific_target)
      #
      # @param handler_target [Symbol]  The symbol that identifies this
      #   ModelObject to driver handlers, the permissions system and other
      #   such parts of bra.  May be nil: see #handler_target for the
      #   behaviour in this case.
      def initialize(handler_target = nil)
        @parent = nil
        @id = nil
        @handler = nil
        @update_channel = nil
        @handler_target = handler_target
      end

      # Gets this object's current ID
      #
      # The ID of a model object identifies it within its parent; the
      # hierarchy of IDs for objects and their successive parents forms the
      # URL of the model in the API space.
      #
      # The ID may be changed by the parent at any point in time.  For example,
      # for playlist items, the ID is their current index in the playlist; when
      # a playlist item is deleted, the IDs of the items after it will be
      # reduced by one.
      #
      # @api public
      # @example  Get the ID of a playlist object.
      #   item.id
      #   #=>5
      #
      # @return [Object]  The current ID of the object.  Typically, this is a
      #   Symbol or Integer.
      def id
        @id_function.try(:call)
      end

      # Returns whether this object supports adding new children
      #
      # By default, this returns false.  Objects that support add_child and
      # remove_child should override this to return true.
      #
      # @api semipublic
      # @example  Checks whether a normal ModelObject can have children.
      #   object.can_have_children?
      #   #=> false
      #
      # @return [Boolean]  false.
      def can_have_children?
        false
      end

      # Gets this object's children, as a hash
      #
      # By default, model objects have no children, so this returns the empty
      # hash.
      def child_hash
        {}
      end

      def children
        nil
      end

      # Methods that form the interface to a composite model object, but do
      # not work in the general case.
      %i{add_child remove_child}.each do |method|
        define_method(method) do |*|
          fail('This model object does not support children.')
        end
      end

      # Registers a handler to be called when this object is modified
      #
      # @param handler [Object] A handler object.  This may contain the methods
      #   put and delete, which handle PUTs and DELETEs respectively.  These
      #   methods shall return true if the model should update itself, and
      #   false if the model should wait until instructed by the driver.
      #
      # @return [self]
      def register_handler(handler)
        @handler = handler
        self
      end

      # GETs this model object
      #
      # A GET is the retrieval of a flattened representation of a model object.
      # See #flat (defined differently for different model objects) for
      # information on what constitutes a flattened representation.
      #
      # @param privileges [PrivilegeSet] The set of privileges the client has.
      #
      # @return [Object] A flat representation of this object.
      def get(privileges)
        fail_if_cannot(:get, privileges)
        flat
      end

      %i{put post delete}.each do |action|
        # Define payload-based server methods.

        define_method(action) do |payload|
          fail_if_cannot(action, payload.privilege_set)
          @handler.send(action, self, payload)
        end

        # Define error-raising stubs for the driver modifiers.
        define_method("driver_#{action}") do |*|
          fail(Bra::Common::Exceptions::NotSupportedByBra)
        end
      end

      # Moves this model object to a new parent with a new ID.
      #
      # @param new_parent [ModelObject] The new parent for this object (can be
      #   nil).
      # @param new_id [Object]  The new ID under which the object will exist in
      #   the parent.
      #
      # @return [self]
      def move_to(new_parent, new_id)
        check_can_have_children(new_parent)

        move_from_old_parent
        @parent = new_parent
        move_to_new_parent(new_id)

        self
      end

      # Checks to make sure a new parent can have children
      def check_can_have_children(parent)
        can = parent.nil? ? true : parent.can_have_children?
        fail('Parent cannot have children.') unless can
      end

      # Performs the move from an old parent, if necessary
      def move_from_old_parent
        @parent.remove_child(id) unless @parent.nil?
      end

      # Performs the move to a new parent, if necessary
      def move_to_new_parent(new_id)
        @parent.add_child(new_id, self) unless @parent.nil?
        @id_function = @parent.try { |parent| parent.id_function(self) }
      end

      # The current URL of this model object with respect to its root
      #
      # The URL is recursively defined: the base case is '' for objects with
      # no parent, and objects with parents take the URL "#{parent_url}/#{id}".
      #
      # @api public
      # @example  Get the URL of an object with no parent
      #   orphan.url
      #   #=> ''
      # @example  Get the URL of an object with a parent
      #   parented.url
      #   #=> ''
      #
      # @return [String] The URL.
      def url
        parent.nil? ? '' : [parent_url, id].join('/')
      end

      def_delegator :@parent, :id, :parent_id
      def_delegator :@parent, :url, :parent_url

      # The identifier used to find handlers and privileges for this object
      #
      # When @handler_target is nil (the default), this is the class name,
      # stripped of its module and converted  to a lowercase_underscored
      # Symbol.  If @handler_target is specified, however, that will be
      # returned instead.
      #
      # @api public
      # @example  Get the default handler target.
      #   ModelObject.new.handler_target
      #   #=> :model_object
      # @example  Get a specified handler target.
      #   ModelObject.new(:widget).handler_target
      #   #=> :widget
      #
      # @return [Symbol]  The handler target for this object.
      def handler_target
        @handler_target || self.class.name.demodulize.underscore.intern
      end
      alias_method :privilege_key, :handler_target

      # Returns the default ID to give to POST payloads
      def default_id
        nil
      end
    end
  end
end
