require 'ury-rapid/model/composite'
require 'ury-rapid/model/constant'
require 'ury-rapid/model/creator'
require 'ury-rapid/model/service_view'
require 'ury-rapid/model/item'
require 'ury-rapid/model/log'
require 'ury-rapid/model/model_object'
require 'ury-rapid/model/server_view'

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
