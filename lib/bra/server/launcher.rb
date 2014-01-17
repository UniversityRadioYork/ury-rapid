require 'rack'

require 'bra/server/app'

module Bra
  module Server
    # Object for launching the bra server.
    #
    # This object exposes a DSL to the bra configuration.
    class Launcher
      def initialize(authenticator)
        @authenticator = authenticator
        @rack = 'thin'
        @host = '0.0.0.0'
        @port = 8181
        @root = '/'
        @config = {cors: {}}

        check_server_em_compatible
      end

      # Sets the host address and port of the server
      def host(address, port)
        @host = address
        @port = port
      end

      # Sets the URL root of the server
      def url_root(root)
        @root = root
      end

      # Sets the file system root of the server
      def file_root(root)
        @config[:root_directory] = root
      end

      # Sets the CORS Allow-Headers of the server
      def allow_headers(*headers)
        cors('Allow-Headers', headers)
      end

      def cors(header, value)
        @config[:cors][header.to_sym] = value
      end

      # Sets the CORS Allow-Credentials header
      def allow_credentials
        cors('Allow-Credentials', [])
      end

      def allow_methods(*methods)
        cors('Allow-Methods', methods)
      end

      # Starts the server
      #
      # This should be called within an EventMachine instance.
      #
      # @return [void]
      def run(model_view)
        Rack::Server.start(
          app: dispatch(model_view), server: @rack, Host: @host, Port: @port
        )
      end

      private

      # Creates the dispatch for the reactor
      #
      # @api private
      #
      # @return [Object]  The dispatch.
      def dispatch(model_view)
        build_rack(@root, make_app(model_view))
      end

      def make_app(model_view)
        App.new(@config, model_view, @authenticator)
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

      COMPATIBLE_SERVERS = %w{thin hatetepe goliath}
    end
  end
end
