require_relative 'composite'

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

      # Returns the handler target of this object
      #
      # For Sets, the target is 'CLASS_set', where the class name is converted
      # to underscore_lowercase.
      #
      # @api semipublic
      # @example Get the handler target of a set of playlists.
      #   a = Set.new(Playlist)
      #   a.handler_target
      #   #=> :playlist_set
      #
      # @return [Symbol] The handler target.
      def handler_target
        @handler_target
      end
    end
  end
end
