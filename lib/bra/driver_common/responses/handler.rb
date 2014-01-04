require 'bra/common/exceptions'
require 'bra/driver_common/handler'

module Bra
  module DriverCommon
    module Responses
      # Abstract class for handlers for a given model object
      #
      # Handlers are installed on model objects so that, when the server
      # attempts to modify the model object, the handler translates it into a
      # playout system command to perform the actual playout system event the
      # model change represents.
      class Handler < Bra::DriverCommon::Handler
        extend Forwardable

        def initialize(parent, response)
          super(parent)
          @response = response
          @model = parent.model
        end

        def_delegators :@model, :get, :put, :post, :delete, :register
        def_delegators :@model, :create_model_object

        # Like delete, but does not fail if the resource does not exist.
        def delete_if_exists(*args)
          delete(*args)
        rescue Bra::Common::Exceptions::MissingResource
          nil
        end
      end
    end
  end
end
