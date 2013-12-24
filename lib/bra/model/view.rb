require 'bra/model/finder'

module Bra
  module Model
    # A view into the model
    #
    # This allows parts of bra that use the model to access it without being
    # coupled to the actual definition of the model.
    class View
      # Initialises the model view
      #
      # @param root [Root]  The model root.
      def initialize(root)
        @root = root
      end

      protected

      # Finds a model object given its URL
      #
      # @api private
      #
      # @return [ModelObject]  The found model object.
      def find(url, &block)
        Finder.find(@root, url, &block)
      end
    end
  end
end
