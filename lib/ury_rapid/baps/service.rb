require 'eventmachine'

require 'ury_rapid/baps/client'
require 'ury_rapid/model/structures/playout_model'
require 'ury_rapid/baps/requests/requester'
require 'ury_rapid/baps/responses/responder'
require 'ury_rapid/services/network_service'

module Rapid
  module Baps
    # The top-level service interface for the BAPS Rapid service
    class Service < Rapid::Services::NetworkService
      extend Forwardable

      # Initialise the service given its service configuration
      #
      # @api      semipublic
      # @example  Create a new BAPS service
      #   service = Service.new(environment)
      def initialize(*_)
        super

        @username = ''
        @password = ''
        @channel_ids = []
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

      def run
        environment.log(:info, 'BAPS service launching.')
        environment.log(:info, "BAPS server: #{@host}:#{@port}")

        initialise_model
        super
      end

      private

      def initialise_model
        add_handlers_to_env
        create_model_components
      end

      def add_handlers_to_env
        environment.add_handlers(request_handlers)
      end

      def create_model_components
        x_baps_maker  = make_x_baps
        playout_maker = Rapid::Model::Structures.playout_model(@channel_ids)

        environment.insert_components('/') do
          instance_eval(&playout_maker)
          instance_eval(&x_baps_maker)

          tree :info, :info do
            constant :channel_mode, true, :channel_mode
          end
        end
      end

      # @return [Proc]
      #   A lambda, to be instance_eval'd into Environment#insert_components.
      def make_x_baps
        server_conf = server_config
        lambda do |*|
          tree :x_baps, :x_baps do
            tree :server, :x_baps_server do
              server_conf.each do |(key, value)|
                constant key, value, :x_baps_server_constant
              end
            end
          end
        end
      end

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
        Rapid::Baps::Responses::Responder.new(environment, requester)
      end

      protected

      def logger
        environment.method(:log)
      end

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
