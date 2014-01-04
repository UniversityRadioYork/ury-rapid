require 'bra/baps/codes'
require 'bra/driver_common/handler_set'

# IMPORTANT: All handlers to be registered with the model tree must be required
# here.
require 'bra/baps/responses/handlers/playback'
require 'bra/baps/responses/handlers/playlist'
require 'bra/baps/responses/handlers/system'

module Bra
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
      class Responder < DriverCommon::HandlerSet
        extend Forwardable

        HANDLER_MODULE = Responses::Handlers

        def_delegators :@requester, :login_authenticate, :login_synchronise

        attr_reader :model

        # Initialises the responder
        #
        # @api semipublic
        #
        # @example Initialise a responder
        #   responder = Responder.new(model, queue)
        #
        # @param model [Model] The Model this Responder will operate on.
        # @param requester [Requester] The Requester via which this Responder
        #   can send BAPS login requests.
        def initialize(model, requester)
          @model = model
          @requester = requester
          @handlers = handler_hash
        end

        # Registers the responder's callbacks with a incoming responses channel
        #
        # @api semipublic
        #
        # @example Register an EventMachine channel
        #   responder = Responder.new(model, queue)
        #   channel = EventMachine::Channel.new
        #   # Attach channel to rest of BAPS here
        #   responder.register(channel)
        #
        # @param channel [Channel] The source channel for responses coming from
        #   BAPS's chat system.
        #
        # @return [void]
        def register(channel)
          channel.subscribe(&method(:handle_response))
        end

        def handle_response(response)
          @handlers.fetch(response.code, UnhandledHandler).run(model, response)
        end
      end

      # Mock handler for when a BAPS code has no registered handler.
      class UnhandledHandler
        # Logs a response with no responder handling function
        #
        # @api private
        #
        # @param response [Hash] A response hash.
        #
        # @return [void]
        def self.run(_, response)
          message = "Unhandled response: #{response.name}"
          if response.code.is_a?(Numeric)
            hexcode = response.code.to_s(16)
            message << " (0x#{hexcode})"
          end
          puts(message)
        end
      end
    end
  end
end
