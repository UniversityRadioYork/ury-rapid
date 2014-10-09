require 'ury_rapid/model/composite'
require 'ury_rapid/model/constant'
require 'ury_rapid/model/creator'
require 'ury_rapid/model/item'
require 'ury_rapid/model/log'
require 'ury_rapid/model/model_object'
require 'ury_rapid/model/view'

module Rapid
  # The module containing the classes that make up Rapid's playout system model
  #
  # The model is an idealised view of the playout system's state, updated when
  # the playout system sends Rapid response messages.  It also provides the
  # interface for sending requests to the playout system, via the use of
  # handlers attached to model objects.
  module Model
  end
end
