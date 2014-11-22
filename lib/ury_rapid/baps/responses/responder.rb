require 'ury_rapid/baps/codes'
require 'ury_rapid/services/handler_set'

# IMPORTANT: All handlers to be registered with the model tree must be required
# here.
require 'ury_rapid/baps/responses/handlers/playback'
require 'ury_rapid/baps/responses/handlers/playlist'
require 'ury_rapid/baps/responses/handlers/system'

module Rapid
  module Baps
    module Responses
      # An object that responds to BAPS server responses by updating the model
      #
      # The responder subscribes to a response parser's output channel, and
      # responds to incoming responses from that channel by firing methods that
      # update the model to reflect the exposed state of the BAPS server.
      #
      # The BAPS responder also has the ability to respond directly to the BAPS
      # server by sending requests to the outgoing requests queue.  This is
      # used, for example, to complete the BAPS login procedure.
      class Responder < Services::HandlerSet
        extend Forwardable

        HANDLER_MODULE = Responses::Handlers

        delegate [:login_authenticate, :login_synchronise] => :@requester
        delegate [:log]                                    => :@model

        # Retrieves the model on which this Responder will operate
        #
        # @api      semipublic
        # @example  Gets the model.
        #   responder = Responder.new(model, queue)
        #   model = responder.model
        #
        # @return [Rapid::Model::ServiceView]
        #   The model view on which this Responder operates.
        attr_reader :model

        # Initialises the responder
        #
        # @api      semipublic
        # @example  Initialise a responder
        #   responder = Responder.new(model, queue)
        #
        # @param model [Rapid::Model::ServiceView]
        #   The model view on this Responder will operate.
        # @param requester [Requester]
        #   The Requester via which this Responder can send BAPS login
        #   requests.
        def initialize(model, requester)
          @model = model
          @requester = requester

          log(:info, 'Initialising BAPS responder.')

          super()
        end

        # Registers the responder's callbacks with a incoming responses channel
        #
        # @api      semipublic
        # @example  Register an EventMachine channel
        #   responder = Responder.new(model, queue)
        #   channel = EventMachine::Channel.new
        #   # Attach channel to rest of BAPS here
        #   responder.register(channel)
        #
        # @param channel [Channel]
        #   The source channel for responses coming from BAPS's chat system.
        #
        # @return [void]
        def register(channel)
          channel.subscribe(&method(:handle_response))
        end

        # Handles a response
        #
        # If the response has no handler, the null handler #unhandled is used.
        #
        # @api      semipublic
        # @example  Get the handler for a specific BAPS code
        #   responder = Responder.new(model, queue)
        #   responder.handle_response(a_response)
        #
        # @param response [Object]
        #   A BAPS response to handle.
        #
        # @return [void]
        def handle_response(response)
          handler_for_code(response.code).call(response)
        end

        # Finds the handler for a specific BAPS response code
        #
        # If there is no handler for the given code, #unhandled is returned.
        #
        # @api      semipublic
        # @example  Get the handler for a specific BAPS code
        #   responder = Responder.new(model, queue)
        #   responder.handler_for_code(0x100)
        #
        # @param code [Code]
        #   A BAPS response code.
        #
        # @return [Proc]
        #   A handler function that may be called with the response to handle.
        def handler_for_code(code)
          @handlers.fetch(code, method(:unhandled))
        end

        # Mock handler for when a BAPS code has no registered handler
        #
        # This handler logs a warning, and does nothing else.
        #
        # @api      semipublic
        # @example  'Handle' an unhandled response
        #   responder = Responder.new(model, queue)
        #   responder.unhandled(a_response)
        #
        # @param response [Object]
        #   A response to 'handle'.
        #
        # @return [void]
        def unhandled(response)
          message = "Unhandled response: #{response.name}"
          if response.code.is_a?(Numeric)
            hexcode = response.code.to_s(16)
            message << " (0x#{hexcode})"
          end

          log(:warn, message)
        end
      end
    end
  end
end
