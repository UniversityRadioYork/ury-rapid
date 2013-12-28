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
    module ModelObject
      extend Forwardable
      include Kankri::PrivilegeSubject
      include Updatable

      def initialize(handler_target = nil)
        @handler_target = handler_target || default_handler_target
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

      # Default implementation of DELETE on model objects
      #
      # This instructs the object's children to delete themselves  Since
      # #each is a no-op on Compo::Leaf, this is safe to use with any model
      # object.
      #
      # @return [void]
      def driver_delete
        each.to_a.each(&:driver_delete)
        clear
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
      attr_reader :handler_target
      alias_method :privilege_key, :handler_target

      # The default handler target for this class
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
      def default_handler_target
        self.class.name.demodulize.underscore.intern
      end

      # Returns the default ID to give to POST payloads
      def default_id
        nil
      end
    end
  end
end
