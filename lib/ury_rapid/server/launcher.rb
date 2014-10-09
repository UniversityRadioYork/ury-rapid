require 'rack'

require 'ury_rapid/server/app'

module Rapid
  module Server
    # Object for launching the Rapid server.
    #
    # This object exposes a DSL to the Rapid configuration.
    class Launcher
      def initialize(logger, authenticator)
        @logger        = logger
        @authenticator = authenticator
        @rack          = 'thin'
        @host          = '0.0.0.0'
        @port          = 8181
        @root          = '/'
        @config        = {}
        @view          = nil

        check_server_em_compatible
      end

      # Sets the host address and port of the server
      def host(address, port)
        @host = address
        @port = port
      end

      def sub_model(update_channel)
        [sub_model_structure(update_channel), method(:view=)]
      end

      # Sets the URL root of the server
      attr_writer :root
      alias_method :url_root, :root=

      # Sets the file system root of the server
      def file_root(root)
        @config[:root_directory] = root
      end

      # Starts the server
      #
      # This should be called within an EventMachine instance.
      #
      # @return [void]
      def run
        Rack::Server.start(
          app: dispatch, server: @rack, Host: @host, Port: @port
        )
      end

      private

      # Creates the dispatch for the reactor
      #
      # @api private
      #
      # @return [Object]  The dispatch.
      def dispatch
        build_rack(@root, make_app)
      end

      def make_app
        App.new(@config, @model_view, @authenticator)
      end

      def build_rack(root, app)
        Rack::Builder.app { map(root) { run(app) } }
      end

      # Makes sure the server supplied can run EventMachine
      #
      # @return [void]
      # Raises a string error if the server does not appear to be EM compatible
      def check_server_em_compatible
        fail_em_incompatible unless em_compatible?
      end

      # Fails with a message about the server not being EventMachine compatible
      def fail_em_incompatible
        fail("Need an EM server, but #{@rack} isn't")
      end

      # Decides whether the server supplied can run EventMachine
      #
      # @return [Boolean] true if the server is compatible; false otherwise.
      def em_compatible?
        COMPATIBLE_SERVERS.include?(@rack)
      end

      COMPATIBLE_SERVERS = %w(thin hatetepe goliath)

      # TODO: Flesh this out and separate it from the launcher!

      attr_accessor :view

      # Constructs the sub-model structure for the server
      #
      # @api  private
      #
      # @param update_channel [Rapid::Model::UpdateChannel]
      #   The update channel that should be used when creating the sub-model
      #   structure.
      #
      # @return [Object]
      #   The sub-model structure.
      def sub_model_structure(update_channel)
        Structure.new(update_channel, @logger)
      end

      # The structure used by the server
      class Structure < Rapid::Model::Creator
        def initialize(update_channel, logger)
          super(update_channel, logger, {})
        end

        # Create the model from the given configuration
        #
        # @api      semipublic
        # @example  Create the model
        #   struct.create
        #
        # @return [Constant]  The finished model.
        def create
          root :sub_root do
            # TODO: Add something here?
          end
        end
      end
    end
  end
end
