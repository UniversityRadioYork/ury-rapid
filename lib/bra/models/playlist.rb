require 'bra/models/composite'
require 'bra/models/item'

module Bra
  module Models
    # A channel playlist, consisting of a list of playlist items.
    class Playlist < ListModelObject
      extend Forwardable
      include ItemContainer

      def_delegator :@children, :size

      def id_is_item?(_)
        true
      end
    end
  end
end
