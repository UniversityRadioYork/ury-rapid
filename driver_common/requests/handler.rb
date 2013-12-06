require_relative '../handler'

module Bra
  module DriverCommon
    module Requests
      # Abstract class for handlers for a given model object
      #
      # Handlers are installed on model objects so that, when the server
      # attempts to modify the model object, the handler translates it into a
      # playout system command to perform the actual playout system event the
      # model change represents.
      class Handler < Bra::DriverCommon::Handler
        extend Forwardable

        protected

        # Sends a request to the parent requester
        #
        # @api semipublic
        #
        # @example Sending a request.
        #   request = Bra::Baps::Requests::Request.new(0)
        #   handler.send(request)
        #
        # @param request [Request] A BAPS request in need of sending.
        #
        # @return [void]
        def_delegator(:@parent, :request)
      end

      # Extension of Handler implementing default behaviour for Variables.
      #
      # By default, the semantics of DELETE on a Variable is that it PUTs the
      # Variable's default initial state.
      class VariableHandler < Handler
        # Requests a DELETE of the given Variable via the BAPS server
        #
        # This effectively sets the Variable to its default value.
        #
        # @api semipublic
        #
        # @example DELETE a Variable
        #   variable_handler.delete(variable)
        #
        # @param variable [Variable] A model object representing a mutable
        #   variable.
        #
        # @return (see #put)
        def delete(variable)
          put(variable, variable.initial_value)
        end
      end
    end
  end
end
