require 'haml'

module Bra
  module Server
    # Sinatra helpers for the API Inspector
    module InspectorHelpers
      def child(inspector, id)
        insp = inspector.inspect_child(id)
        inspector_haml(insp)
      end

      def navigation(inspector)
        haml(
          :in_out_links,
          locals: {
            resource_url: inspector.resource_url,
            inner: inspector.inner
          }
        )
      end

      # Renders an API Inspector instance using HAML.
      def inspector_haml(inspector)
        haml(inspector.resource_type, locals: { inspector: inspector })
      rescue Errno::ENOENT
        haml(inspector.resource_general_type, locals: { inspector: inspector })
      end
    end

    # An instance of the API Inspector
    #
    # The API Inspector is bra's HTML output.  It allows the API space to be
    # navigated and interacted with in a basic way.
    #
    # Because the API inspector needs more information about the model than
    # its flat representation, the Inspector object is used to hold the extra
    # state.
    class Inspector
      extend Forwardable

      attr_reader :inner

      # Initialises an instance of the API Inspector
      #
      # @param request [Request]  The HTTP request that spawned this Inspector.
      # @param target [ModelObject]  The object to inspect.
      # @param privilege_set [PrivilegeSet]  The set of privileges that the
      #   inspector instance may use.
      # @param inner [Boolean]  If true, this inspector is being used inside
      #   another inspector.
      def initialize(request, target, privilege_set, inner = false)
        @request = request
        @target = target
        @resource = target.get(privilege_set)
        @inner = inner
        @privilege_set = privilege_set
      end

      def title
        @inner ? resource_id : resource_url
      end

      attr_reader :resource

      # Retrieves the type of the target
      def resource_type
        json? ? :json : @target.handler_target
      end

      def resource_general_type
        @target.class.name.demodulize.underscore.intern
      end

      def_delegator :@target, :url, :resource_url
      def_delegator :@target, :id, :resource_id
      def_delegator :@target, :handler_target, :resource_handler_target

      # Creates a new Inspector inspecting one of target's children
      def inspect_child(id)
        Inspector.new(@request, @target.get_child(id), @privilege_set, true)
      end

      private

      # Retrieves a map of child IDs to their resource type
      def resource_child_types
        @resource_child_types = target.child_hash.map(&method(:type_symbol))
      end

      # @return [Boolean]  True if the request was for the JSON format of a
      #   model object.
      def json?
        @request.params.key? 'json'
      end
    end
  end
end
