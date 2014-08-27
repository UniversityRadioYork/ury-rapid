require 'eventmachine'

require 'rapid/baps/client'
require 'rapid/baps/models'
require 'rapid/baps/requests/requester'
require 'rapid/baps/responses/responder'

module Rapid
  module Baps
    # The top-level service interface for the BAPS Rapid service
    class Service
      extend Forwardable

      # Initialise the service given its service configuration
      #
      # @param config [Hash]  The configuration hash for the service.
      # @param logger [Object]  An object that can be used to log messages from
      #   the service.
      def initialize(logger)
        @logger = logger

        # We need a queue for requests to the BAPS server to be funneled
        # through.  This will later need to be given to the actual BAPS client
        # to read from, and also to the requester to write to.
        # This doesn't need to be an instance variable, as it is taken up by
        # @requester and @client.
        @queue = EventMachine::Queue.new

        # The requester contains all the logic for instructing BAPS to make
        # model changes happen.
        @requester = Rapid::Baps::Requests::Requester.new(@queue, @logger)

        # Default configuration values.
        @host     = 'localhost'
        @port     = 1350
        @username = ''
        @password = ''
      end

      #
      # Configuration DSL
      #

      def host(host, port)
        @host = host
        @port = port
      end

      attr_writer :username
      alias_method :username, :username=

      attr_writer :password
      alias_method :password, :password=

      def num_channels(channels)
        @channel_ids = (0...channels).to_a
      end

      #
      # End configuration DSL
      #

      # Asks the service to construct an instance of its model
      #
      # This is intended to be called by the Rapid launcher when initialising
      # the services.
      def sub_model(update_channel)
        [
          create_extender(update_channel),
          ->(service_view) { @service_view = service_view }
        ]
      end

      # Begin running the service, given a view of the completed model
      #
      # This function is always run within an EventMachine run block.
      def run
        # Most of the actual low-level BAPS poking is contained inside this
        # client object, which is what hooks into the Rapid EventMachine
        # instance.  We need to give it access to parts of the service config
        # so it knows where and how to connect to BAPS.
        client = Rapid::Baps::Client.new(@queue, @logger, @host, @port)

        # The responder receives responses from the BAPS server via the client
        # and reacts on them, either updating the model or asking the requester
        # to intervene.
        #
        # We'd make the responder earlier, but we need access to the model,
        # which we only get definitive access to here.
        responder = Rapid::Baps::Responses::Responder.new(
          @service_view,
          @requester
        )

        # Now we can run the client, passing it the responder so it can send
        # BAPS responses to it.  The client will get BAPS requests sent to it
        # via the queue, thus completing the communication paths.
        client.run(responder)

        # Finally, get the ball rolling by asking the requester to initiate
        # log-in.  This sets up a chain reaction between the requester and
        # responder that brings up the server connection.
        @requester.login_initiate
      end

      private

      def_delegator :@requester, :add_handlers

      def log_initialisation
        @logger.info('Initialising BAPS service...')
        @logger.info("BAPS server: #{@config[:host]}:#{@config[:port]}")
      end

      def create_extender(update_channel)
        make_structure(update_channel).tap do |structure|
          @requester.add_handlers(structure)
        end
      end

      def make_structure(update_channel)
        Rapid::Baps::Model::Creator.new(
          update_channel,
          @logger,
          players: @channel_ids,
          playlists: @channel_ids,
          server_config: server_config
        )
      end

      def server_config
        {
          host: @host,
          port: @port,
          username: @username,
          password: @password
        }
      end
    end
  end
end
