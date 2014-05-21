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

      protected

      # Finds a model object given its URL
      #
      # @api private
      #
      # @return [ModelObject]  The found model object.
      def find(url, &block)
        Compo::UrlFinder.find(@root, url, &block)
      end
    end
  end
end
