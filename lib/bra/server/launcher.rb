require 'rack'

require 'bra/server/app'

module Bra
  module Server
    # Object for launching the bra server.
    class Launcher
      def initialize(config, authenticator)
        @app = App.new(config, authenticator)
        @rack, @host, @port, @root = config.values_at(*%i{rack host port root})
        @dispatch = make_dispatch

        check_server_em_compatible
      end

      # Starts the server
      #
      # This should be called within an EventMachine instance.
      #
      # @return [void]
      def run(model_view)
        @app.register_model(model_view)
        Rack::Server.start(
          app: @dispatch, server: @rack, Host: @host, Port: @port
        )
      end

      private

      # Creates the dispatch for the reactor
      #
      # @return [Object] the dispatch.
      def make_dispatch
        root, app = @root, @app
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
