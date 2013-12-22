require 'bra/common/hash'
require 'bra/model/composite'
require 'bra/model/item'
require 'bra/model/variable'

module Bra
  module Model
    # A player in the model, which represents a channel's currently playing
    # song and its state.
    class Player < HashModelObject
      include ItemContainer
    end
  end
end
