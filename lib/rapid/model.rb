require 'rapid/model/composite'
require 'rapid/model/constant'
require 'rapid/model/creator'
require 'rapid/model/service_view'
require 'rapid/model/item'
require 'rapid/model/log'
require 'rapid/model/model_object'
require 'rapid/model/server_view'

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
