module Bra
  module Baps
    module Requests
      # Abstract class for handlers for a given model object.
      #
      # DO NOT put this class in the Handlers module.  This will cause the BAPS
      # driver to attempt to register it as a handler, which will fail.
      class Handler
        extend Forwardable

        # Initialises the Handler
        #
        # @api semipublic
        #
        # @example Initialising a Handler with a parent Requester.
        #   queue = EventMachine::Queue.new
        #   requester = Bra::Baps::Requests::Requester.new(queue)
        #   handler = Bra::Baps::Requests::Handler.new(requester)
        #
        # @param parent [Requester] The main Requester to which requests shall
        #   be sent.
        def initialize(parent)
          @parent = parent
        end

        protected

        # Sends a request to the parent requester
        #
        # @api semipublic
        #
        # @example Sending a request.
        #   request = Bra::Baps::Requests::Request.new(0)
        #   subrequester.send(request)
        #
        # @param request [Request] A BAPS request in need of sending.
        #
        # @return [void]
        def_delegator(:@parent, :send)
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
