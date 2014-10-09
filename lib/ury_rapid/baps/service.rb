require 'eventmachine'

require 'ury_rapid/baps/client'
require 'ury_rapid/baps/models'
require 'ury_rapid/baps/requests/requester'
require 'ury_rapid/baps/responses/responder'
require 'ury_rapid/service_common/network_service'

module Rapid
  module Baps
    # The top-level service interface for the BAPS Rapid service
    class Service < Rapid::ServiceCommon::NetworkService
      extend Forwardable

      # Initialise the service given its service configuration
      #
      # @api      semipublic
      # @example  Create a new BAPS service
      #   service = Service.new(logger, view, auth)
      #
      # @param logger [Object]
      #   An object that can be used to log messages from the service.
      # @param view [Rapid::Model::ServerView]
      #   A server view of the entire model.
      # @param auth [Object]
      #   An authentication provider.
      def initialize(logger, auth)
        super(logger, auth)

        @username = ''
        @password = ''
      end

      #
      # Configuration DSL (extends the NetworkService DSL)
      #

      # username [String] - sets the BAPS login username.
      attr_writer :username
      alias_method :username, :username=

      # password [String] - sets the BAPS login password (cleartext).
      attr_writer :password
      alias_method :password, :password=

      # num_channels [Integer] - sets the channel count of the BAPS server.
      # This should agree with the number of channels configured in BAPS.
      def num_channels(channels)
        @channel_ids = (0...channels).to_a
      end

      #
      # End configuration DSL
      #

      private

      # Sets the default host for BAPS
      #
      # @api  private
      #
      # @return [Array]
      #   A tuple [host, port].
      def default_host
        ['localhost', 1350]
      end

      # Constructs the BAPS client
      #
      # @api  private
      #
      # @param queue [EventMachine::Queue]
      #   The requests queue, which will be read by the client.
      # @param host [String]
      #   The network host to which the client should connect.
      # @param port [Integer]
      #   The network port to which the client should connect.
      #
      # @return [Object]
      #   The BAPS client object.
      def make_client(queue, host, port)
        Rapid::Baps::Client.new(queue, logger, host, port)
      end

      # Constructs the BAPS requester
      #
      # @api  private
      #
      # @param queue [EventMachine::Queue]
      #   The requests queue, which will be written to by the requester.
      #
      # @return [Object]
      #   The BAPS requester object.
      def make_requester(queue)
        Rapid::Baps::Requests::Requester.new(queue, logger)
      end

      # Constructs the BAPS responder
      #
      # @api  private
      #
      # @param requester [Object]
      #   The requester, which is sent to the responder so that responses can
      #   trigger further requests.
      #
      # @return [Object]
      #   The BAPS responder object.
      def make_responder(requester)
        Rapid::Baps::Responses::Responder.new(view, requester)
      end

      protected

      # Perform any necessary initial requests to the network server
      #
      # BAPS requires a login, so we do it here.
      #
      # @api  private
      #
      # @param requester [Object]
      #   The requester object to which requests should be made.
      #
      # @return [void]
      def initial_requests(requester)
        # Finally, get the ball rolling by asking the requester to initiate
        # log-in.  This sets up a chain reaction between the requester and
        # responder that brings up the server connection.
        requester.login_initiate
      end

      private

      def sub_model_structure(update_channel)
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
