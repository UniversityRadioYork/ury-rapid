require 'digest'

# IMPORTANT: All handlers to be registered with the model tree must be required
# here.
require_relative 'handlers/playback'
require_relative 'handlers/playlist'

module Bra
  module Baps
    module Requests
      # An object that sends requests to the BAPS server on behalf of bra.
      #
      # The Requester intercepts model changes and converts them to BAPS
      # requests, sending them to BAPS via a requests queue.
      #
      # The responses from the BAPS server are sent to the Responder, which
      # updates the model accordingly.
      #
      # The Requester delegates the request generation to several SubRequester
      # objects, which are defined elsewhere.
      class Requester
        # Initialises the Requester
        #
        # @api semipublic
        #
        # @example Initialising a Requester with an EventMachine Queue.
        #   queue = EventMachine::Queue.new
        #   requester = Bra::Baps::Requests::Requester.new(queue)
        #
        # @param queue [Queue] The quests queue used for sending requests to
        #   the BAPS server.
        def initialize(queue)
          @queue = queue
        end

        # Prepares an incoming model configuration by adding handlers
        #
        # This ensures that attempts by the server to update the model are
        # re-routed towards BAPS.
        #
        # This returns its changes, but may or may not mutate the original
        # model_config.
        #
        # @api semipublic
        #
        # @example Prepare an incoming model configuration.
        #   cfg = {}
        #   cfg = configure_model(cfg)
        #
        # @param model_config [Hash] The incoming model configuration hash.
        #
        # @return [Hash] The prepared model configuration hash, which may be
        #   the same object.
        def configure_model(model_config)
          # Instantiate and insert all model change handlers into the model
          # config.
          #
          # There is no reason other than efficiency for this to be a mutating
          # action - if needs be, .clone or reduce the model_config.
          handlers.each do |handler|
            puts "Registering handler #{handler.name} for #{handler::TARGET}"
            model_config[handler::TARGET] = handler.new(self)
          end
          # We still need to return the hash, even though we've mutated the
          # existing one.
          model_config
        end

        # Sends a request to the BAPS server
        #
        # @api semipublic
        #
        # @example Send a request.
        #   requester.send(Bra::Baps::Requests::Request.new(0)
        #
        # @param request [Request] The request to send.
        #
        # @return [void]
        def send(request)
          request.to(@queue)
        end

        # TODO(mattbw): Perhaps move these login commands elsewhere.

        # Initiates the BAPS login procedure
        #
        # @api semipublic
        #
        # @return [void]
        def login_initiate
          send(Request.new(Codes::System::SET_BINARY_MODE))
        end

        # Sends credentials to the BAPS server to further log-in
        #
        # login_initiate MUST have been called previously.
        #
        # @api semipublic
        #
        # @example Log into BAPS.
        #   requester.login_authenticate('Elvis', 'hunter2', 'abc123')
        #
        # @param username [String] The password to use to authenticate to the
        #   BAPS server.
        # @param password [String] The (plaintext) password to use to
        #   authenticate to the BAPS server.
        # @param seed     [String]- The session seed yielded by initiation.
        #
        # @return [void]
        def login_authenticate(username, password, seed)
          password_hash = Digest::MD5.hexdigest(password.to_s)
          full_hash = Digest::MD5.hexdigest(seed + password_hash)

          send(
            Request
            .new(Codes::System::LOGIN)
            .string(username.to_s)
            .string(full_hash)
          )
        end

        # Instructs BAPS to synchronise its state with bra and start chatting
        #
        # @api semipublic
        #
        # @return [void]
        def login_synchronise
          # Subcode 3: Synchronise and add to chat.
          send(Request.new(Codes::System::SYNC, 3))
        end

        private

        # Compiles a list of all handlers to register
        #
        # This is everything require'd by the Requester that is in the
        # Bra::Baps::Requests::Handlers module.
        #
        # @return [Array] An array of handlers as described above.
        def handlers
          Handlers.constants.map(&Handlers.method(:const_get))
        end
      end
    end
  end
end
