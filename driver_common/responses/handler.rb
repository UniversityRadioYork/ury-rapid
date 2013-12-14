require_relative '../handler'

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

        def initialize(parent)
          super(parent)
          @model = parent.model
        end

        protected

        # Shorthand for @model.driver_X_url.
        def_delegator(:@model, :find_url, :find)
        def_delegator(:@model, :driver_put_url, :put)
        def_delegator(:@model, :driver_post_url, :post)
        def_delegator(:@model, :driver_delete_url, :delete)
      end
    end
  end
end
