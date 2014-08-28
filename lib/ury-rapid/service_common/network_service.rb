require 'ury-rapid/service_common/service'

module Rapid
  module ServiceCommon
    # A base class for Rapid services that connect to a network server
    #
    # This class provides an opinionated framework for TCP-based services,
    # that separates the service-specific workload into three separate objects:
    #
    # * A requester, which hooks into the service model and translates model
    #   changes into raw request strings to send to the downstream server;
    # * A responder, which receives parsed responses from the downstream
    #   server and updates the model to reflect them;
    # * A client, which is given a requests queue and access to the responder,
    #   and maintains the connection as well as the machinery needed to read
    #   and parse responses.
    #
    # See the Service class for information about methods that must be
    # implemented by subclasses of NetworkService. In addition, subclasses must
    # implement:
    #
    # * #make_requester, which returns a requester given the requests queue;
    # * #make_responder, which returns a responder given the requester;
    # * #make_client, which returns a client given the requests queue, host and
    #   port;
    # * #default_host, which returns a tuple of default host and port.
    #
    #
    # They may also override:
    #
    # * #initial_requests, which is given the requester and can be used to make
    #   any initial requests necessary to start the session with the network
    #   server upon the service start.
    class NetworkService < Service
      # Initialises the service
      #
      # @api      semipublic
      # @example  Create a new network service, given a logger
      #   service = Service.new(logger)
      #
      # @param logger [Object]
      #   An object that can be used to log messages from the service.
      def initialize(logger)
        super(logger)

        # We need a queue to hold requests to the network server.  This will
        # later need to be given to the client for reading, and also to the
        # requester for writing.
        @queue = EventMachine::Queue.new

        # The requester contains all the logic for instructing the network
        # server to make model changes happen.
        @requester = make_requester(@queue)

        host(*default_host)
      end

      #
      # Configuration DSL
      #

      # Sets the host and port of this network service's downstream server
      #
      # @api      public
      # @example  Set the service to connect to localhost, port 1350
      #   # (in config.rb)
      #   host 'localhost', 1350
      #
      # @param host [String]
      #   The name or address of the downstream host.
      # @param port [Integer]
      #   The network port of the downstream host.
      #
      # @return [void]
      def host(host, port)
        @host = host
        @port = port
      end

      #
      # End configuration DSL
      #

      # Asks the service to prepare its sub-model structure
      #
      # This is intended to be called by the Rapid launcher when initialising
      # the services.
      #
      # @api      semipublic
      # @example  Request the sub-model structure of this Service
      #   sub_model, register_view_proc = service.sub_model
      #
      # @param update_channel [Rapid::Model::UpdateChannel]
      #   The update channel that should be used when creating the sub-model
      #   structure.
      #
      # @return [Array]
      #   A tuple of the completed sub-model structure, and a proc that should
      #   be called with a ServiceView of the completed model.
      def sub_model(update_channel)
        # We do the same as a normal Service, but tap into the structure before
        # returning it so we can make sure the requester gets to install its
        # handlers in the structure before it gets built by the launcher.
        super(update_channel).tap do |structure, _proc|
          @requester.add_handlers(structure)
        end
      end

      # Begin running the service
      #
      # This function is always run within an EventMachine run block.
      #
      # @api
      # @example  Run the network service.
      #   ns.run
      #
      # @return [void]
      def run
        # Most of the actual network server poking is contained inside this
        # client object, which is what hooks into the Rapid EventMachine
        # instance.  We need to give it access to parts of the service config
        # so it knows where and how to connect to the server.
        client = make_client(@queue, @host, @port)

        # The responder receives responses from downstream via the client and
        # reacts on them, either updating the model or asking the requester to
        # intervene.
        #
        # We'd make the responder earlier, but we need access to a service
        # view into the model, which we aren't guaranteed to have until
        # run-time.
        responder = make_responder(@requester)

        # Now we can run the client, passing it the responder so it can send
        # BAPS responses to it.  The client will get BAPS requests sent to it
        # via the queue, thus completing the communication paths.
        client.run(responder)

        # Finally, the network service may wish to send some initial requests
        # to the downstream server here.
        initial_requests(@requester)
      end

      protected

      # Perform any necessary initial requests to the network server
      #
      # By default, this is empty, but can be overridden by subclasses.
      #
      # @api  private
      #
      # @param requester [Object]
      #   The requester object to which requests should be made.
      #
      # @return [void]
      def initial_requests(_requester)
        # Intentionally left blank
      end
    end
  end
end
