require 'eventmachine'

require 'bra/baps/client'
require 'bra/baps/models'
require 'bra/baps/requests/requester'
require 'bra/baps/responses/responder'

module Bra
  module Baps
    # The top-level driver interface for the BAPS BRA driver
    class Driver
      extend Forwardable

      # Initialise the driver given its driver configuration
      #
      # @param config [Hash]  The configuration hash for the driver.
      # @param logger [Object]  An object that can be used to log messages from
      #   the driver.
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
        @requester = Bra::Baps::Requests::Requester.new(@queue, @logger)

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

      def sub_model(update_channel)
        [
          create_extender(update_channel),
          ->(driver_view) { @driver_view = driver_view }
        ]
      end

      # Begin running the driver, given a view of the completed model
      #
      # This function is always run within an EventMachine run block.
      def run
        # Most of the actual low-level BAPS poking is contained inside this
        # client object, which is what hooks into the BRA EventMachine
        # instance.  We need to give it access to parts of the driver config so
        # it knows where and how to connect to BAPS.
        client_config = [@host, @port, @username, @password]
        client = Bra::Baps::Client.new(@queue, @logger, *client_config)

        # The responder receives responses from the BAPS server via the client
        # and reacts on them, either updating the model or asking the requester
        # to intervene.
        #
        # We'd make the responder earlier, but we need access to the model,
        # which we only get definitive access to here.
        responder = Bra::Baps::Responses::Responder.new(
          @driver_view,
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
        @logger.info('Initialising BAPS driver...')
        @logger.info("BAPS server: #{@config[:host]}:#{@config[:port]}")
      end

      def create_extender(update_channel)
        make_structure(update_channel).tap do |structure|
          @requester.add_handlers(structure)
        end
      end

      def make_structure(update_channel)
        Bra::Baps::Model::Creator.new(
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
