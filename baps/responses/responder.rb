require_relative '../codes'
require_relative '../../driver_common/handler_set'

# IMPORTANT: All handlers to be registered with the model tree must be required
# here.
require_relative 'handlers/playback'
require_relative 'handlers/playlist'


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
      # server by sending requests to the outgoing requests queue.  This is used,
      # for example, to complete the BAPS login procedure.
      class Responder < DriverCommon::HandlerSet
        HANDLER_MODULE = Responses::Handlers

        attr_reader :model

        # Initialises the responder
        #
        # @api semipublic
        #
        # @example Initialise a responder
        #   responder = Responder.new(model, queue)
        #
        # @param model [Model] The Model this Responder will operate on.
        # @param requester [Requester] The Requester via which this Responder can
        #   send BAPS login requests.
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
          channel.subscribe(&method(handle_response))
        end

        def handle_response(response)
          f = @handlers[response[:code]]
          f.call(response) if f
          unhandled(response) unless f
        end

        private

        # Logs a response with no responder handling function
        #
        # @api private
        #
        # @param response [Hash] A response hash.
        #
        # @return [void]
        def unhandled(response)
          message = "Unhandled response: #{response[:name]}"
          if response[:code].is_a?(Numeric)
            hexcode = response[:code].to_s(16)
            message << " (0x#{hexcode})"
          end
          puts(message)
        end

        # Constructs a response matching hash for system functions
        #
        # @api private
        #
        # @return [Hash] The response hash, which should be merged into the main
        #   response table.
        def system_functions
          {
            Codes::System::CLIENT_ADD => method(:client_add),
            Codes::System::CLIENT_REMOVE => method(:client_remove),
            Codes::System::LOG_MESSAGE => method(:log_message),
            Codes::System::SEED => method(:login_seed),
            Codes::System::LOGIN_RESULT => method(:login_result)
          }
        end

        # Registers an item into channel playlist
        #
        # @api private
        #
        # @param response [Hash] A BAPS response containing the item.
        #
        # @return [void]
        def item_data(response)
          id, index = response.values_at(:subcode, :index)
          type, title = response.values_at(:type, :title)
          item = Bra::Models::Item.new(track_type_baps_to_bra(type), title)

          @model.driver_post_url("channels/#{id}/playlist/", { index => item })
        end

        # Intentionally ignores the response
        #
        # @api private
        #
        # @param _ [Hash] The (ignored) response.
        #
        # @return [void]
        def nop(_)
          nil
        end

        alias_method :item_count, :nop
        alias_method :client_add, :nop
        alias_method :client_remove, :nop

        # Logs a BAPS internal message
        #
        # @api private
        #
        # @param response [Hash] The response containing the internal message.
        #
        # @return [void]
        def log_message(response)
          # TODO: actually log this message
          puts "[LOG] #{response[:message]}"
        end

        # TODO(mattbw): Move these somewhere more relevant?
        module LoginErrors
          OK = 0
          INCORRECT_USER = 1
          EMPTY_USER = 2
          INCORRECT_PASSWORD = 3
        end

        # Receives a seed from the BAPS server and acts upon it
        #
        # @api private
        #
        # @param response [Hash] The BAPS response containing the seed.
        #
        # @return [void]
        def login_seed(response)
          username = @model.find_url('x_baps/server/username', &:value)
          password = @model.find_url('x_baps/server/password', &:value)
          seed = response[:seed]
          # Kurse all SeeDs.  Swarming like lokusts akross generations.
          #   - Sorceress Ultimecia, Final Fantasy VIII
          @requester.login_authenticate(username, password, seed) if seed
        end

        # Receives a login response from the server and acts upon it
        #
        # @api private
        #
        # @param response [Hash] The BAPS response containing the login result.
        #
        # @return [void]
        def login_result(response)
          code, string = response.values_at(*%i(subcode details))
          is_ok = code == LoginErrors::OK
          @requester.login_synchronise if is_ok
          unless is_ok
            puts("BAPS login FAILED: #{string}, code #{code}.")
            EventMachine.stop
          end
        end
      end
    end
  end
end
