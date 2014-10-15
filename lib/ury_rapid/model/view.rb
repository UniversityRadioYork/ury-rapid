require 'compo'
require 'ury_rapid/model/component_inserter'
require 'ury_rapid/service_common/requests/null_handler'

module Rapid
  module Model
    # A view into the model
    #
    # This allows parts of Rapid that use the model to access it without being
    # coupled to the actual definition of the model.
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
