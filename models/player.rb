require_relative 'composite'
require_relative 'variable'
require_relative 'item'
require_relative '../utils/hash'

module Bra
  module Models
    class PlayerSet < HashModelObject
    end

    # Public: A player in the model, which represents a channel's currently
    # playing song and its state.
    class Player < HashModelObject
      include ItemContainer
    end
  end
end
