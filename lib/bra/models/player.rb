require 'bra/common/hash'
require 'bra/models/composite'
require 'bra/models/item'
require 'bra/models/variable'

module Bra
  module Models
    # A player in the model, which represents a channel's currently playing
    # song and its state.
    class Player < HashModelObject
      include ItemContainer
    end
  end
end
