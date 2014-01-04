require 'bra/model/composite'
require 'bra/model/creator'
require 'bra/model/driver_view'
require 'bra/model/item'
require 'bra/model/model_object'
require 'bra/model/server_view'
require 'bra/model/constant'

module Bra
  # The module containing the classes that make up bra's playout system model
  #
  # The model is an idealised view of the playout system's state, updated when
  # the playout system sends bra response messages.  It also provides the
  # interface for sending requests to the playout system, via the use of
  # handlers attached to model objects.
  module Model
  end
end
