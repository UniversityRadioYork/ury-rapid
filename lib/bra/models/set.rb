require 'bra/models/composite'

module Bra
  module Models
    # A model object that represents a set of other objects.
    class Set < HashModelObject
      # Initialises a Set
      #
      # @api semipublic
      # @example Initialise a set of playlists.
      #   Set.new(Playlist)
      #
      # @param handler_target [Symbol] The symbol identifying this set to the
      #   handler registrar.
      def initialize(handler_target)
        @handler_target = handler_target
        super()
      end

      attr_reader :handler_target
    end
  end
end
