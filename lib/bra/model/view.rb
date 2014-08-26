require 'compo'

module Bra
  module Model
    # A view into the model
    #
    # This allows parts of bra that use the model to access it without being
    # coupled to the actual definition of the model.
    class View
      extend Forwardable

      # Initialises the model view
      #
      # @param root [Root]  The model root.
      def initialize(root)
        @root = root
      end

      # Allow access to the model's updates channel
      def_delegator :@root, :register_for_updates
      def_delegator :@root, :deregister_from_updates

      # Logs an error message in the bra log
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
        find('log') { |log| log.service_post(severity, message) }
      end

      protected

      # Finds a model object given its URL
      #
      # @api private
      #
      # @return [ModelObject]  The found model object.
      def find(url, &block)
        Compo::Finders::Url.find(@root, url, &block)
      end
    end
  end
end
