require 'digest'

require 'bra/driver_common/handler_set'
require 'bra/baps/requests/request'

# IMPORTANT: All handlers to be registered with the model tree must be required
# here.
require 'bra/baps/requests/handlers/playback'
require 'bra/baps/requests/handlers/playlist'

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
      class Requester < DriverCommon::HandlerSet
        extend Forwardable

        HANDLER_MODULE = Requests::Handlers

        # Initialises the Requester
        #
        # @api semipublic
        #
        # @example Initialising a Requester with an EventMachine Queue.
        #   queue = EventMachine::Queue.new
        #   logger = Logger.new(STDOUT)
        #   requester = Bra::Baps::Requests::Requester.new(queue, logger)
        #
        # @param queue [Queue]  The requests queue used for sending requests to
        #   the BAPS server.
        # @param logger [Object]  The Logger-compatible object used for logging
        #   the handlers registered.
        def initialize(queue, logger)
          @queue = queue
          @logger = logger

          logger.info('Initialising BAPS requester.')

          super()
        end

        def_delegator :@logger, :send, :log

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
        # @example Adds this Requester's handlers into the model configuration.
        #   cfg = add_handlers(cfg)
        #
        # @param model_config [Config] The incoming model configuration.
        #
        # @return [void]
        def add_handlers(model_config)
          # There is no reason other than efficiency for this to be a mutating
          # action - if needs be, merge instead of merge!.
          model_config.add_handlers(@handlers)
        end

        # Sends a request to the BAPS server
        #
        # @api public
        # @example  Send a request.
        #   requester.request(Bra::Baps::Codes::Playlist::LOAD, channel) do |r|
        #     r.uint32(index)
        #   end
        #
        # @param code [Integer]  The BAPS protocol code for the request: this
        #   will usually be a value from Bra::Baps::Codes.
        # @param subcode [Integer]  The sub-code for the request (usually a
        #   channel ID or similar): this will default to 0 if not given.
        #
        # @yieldparam request [Request]  The request that is about to be sent,
        #   so that it can have arguments added to it using the #uint32,
        #   #string and similar methods.
        #
        # @return [void]
        def request(code, subcode = 0, &block)
          request = Request.new(code, subcode)
          request.instance_exec(&block) if block
          request.to(@queue)
        end

        # TODO(mattbw): Perhaps move these login commands elsewhere.

        # Initiates the BAPS login procedure
        #
        # @api semipublic
        #
        # @return [void]
        def login_initiate
          request(Codes::System::SET_BINARY_MODE)
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

          request(Codes::System::LOGIN) { string username.to_s, full_hash }
        end

        # Instructs BAPS to synchronise its state with bra and start chatting
        #
        # @api semipublic
        #
        # @return [void]
        def login_synchronise
          # Subcode 3: Synchronise and add to chat.
          request(Codes::System::SYNC, 3)
        end
      end
    end
  end
end
