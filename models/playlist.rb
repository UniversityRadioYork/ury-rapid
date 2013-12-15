require_relative 'composite'
require_relative 'item'

module Bra
  module Models
    class PlaylistSet < HashModelObject
    end

    # A channel playlist, consisting of a list of playlist items.
    class Playlist < ListModelObject
      extend Forwardable
      include ItemContainer

      def_delegator :@children, :size
    end
  end
end
