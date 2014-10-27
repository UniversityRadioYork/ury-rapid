require 'compo'
require 'ury_rapid/model/component_inserter'
require 'ury_rapid/services/requests/null_handler'

module Rapid
  module Model
    # A view into the Rapid model
    #
    # A View tracks two different model roots: the 'global root', which is the
    # top of the entire model, and the 'local root', which is the top of the
    # part of the model the View's user is authorised to update directly.  For
    # example, a Service generally has a View whose local root is that
    # Service's sub-model.
    #
    # The global/local distinction is primarily one of security: only the owner
    # of a section of model can actually get at it directly, and only
    # authorised services/clients can interact with other parts of the model
    # (and, thus, other services).
    #
    # From the global root, a View can perform indirect queries (#get, #post,
    # #put, and #delete).  These are named by analogy to HTTP and REST APIs,
    # primarily for historical reasons; they require the View's caller to have
    # sufficient privileges (via a PrivilegeSet); and they do not directly
    # update the model but instead request that whatever handler code is
    # attached to the affected parts of the model is activated.
    #
    # From the local root, a View can grab model objects directly by URL
    # (#find), as well as perform direct updates on the model structure
    # (#insert, #replace, and #kill).  These do not require privileges, and
    # directly manipulate the model without any handlers being called.
    class View
      extend Forwardable

      # Initialises the model view
      #
      # @param global_root [ModelObject]
      #   The root of the entire Rapid model, which can be queried (but not
      #   modified) by this View.
      # @param local_root [ModelObject]
      #   The root of the part of the Rapid model that this View can modify
      #   directly.
      def initialize(global_root, local_root)
        @global_root = global_root
        @local_root  = local_root
      end

      # Creates a View of the same global root, but a different local root
      #
      # This is usually used in the situation where a service A has a view VA,
      # and is creating a child service B.  VB should contain a reference to
      # the same global root, as it is on the same model as A and VA, but B
      # should not be able to update all of A's model space, so its view VB is
      # VA but with the local root set to B's sub-model.
      #
      # @param local_root [ModelObject]
      #   The new local root.
      # @return [View]
      #   A new View, with the same global root as this View, but the given
      #   local root.
      def with_local_root(local_root)
        View.new(@global_root, local_root)
      end

      #
      # Global API
      #

      # Logs an error message in the Rapid log
      #
      # @api  public
      # @example  Log an error.
      #   view.log(:error, 'The system is down!')
      #
      # @param severity [Symbol]  The severity level of the log message.  This
      #   must be one of :debug, :info, :warn, :error or :fatal.
      # @param message [String]  The log message itself.
      #
      # @return [void]
      def log(severity, message)
        global_find('log') { |log| log.insert(severity, message) }
      end

      # TODO: This is a security risk!
      # Maybe have a GetWrapper class that restricts what can be done
      def get(url)
        global_find(url) { |object| yield object }
      end

      %i(put post delete).each do |action|
        define_method(action) do |url, privilege_set, raw_payload|
          global_find(url) do |object|
            payload = make_payload(action, privilege_set, raw_payload, object)
            object.send(action, payload)
          end
        end
      end

      #
      # Local API
      #

      %w(insert replace remove).each do |action|
        define_method(action) do |url, *args|
          find(url) { |resource| resource.send(action, *args) }
        end
      end

      # Finds a model object in the local root given its URL
      #
      # @api private
      #
      # @return [ModelObject]  The found model object.
      def find(url, &block)
        find_in(@local_root, url, &block)
      end

      private

      # Finds a model object in the global root given its URL
      #
      # @api private
      #
      # @return [ModelObject]  The found model object.
      def global_find(url, &block)
        find_in(@global_root, url, &block)
      end

      def find_in(root, url, &block)
        block ||= ->(x) { x }
        Compo::Finders::Url.find(root, url, &block)
      end

      def make_payload(action, privilege_set, raw_payload, object)
        Common::Payload.new(
          raw_payload, privilege_set,
          (action == :put ? object.id : object.default_id)
        )
      end
    end
  end
end
