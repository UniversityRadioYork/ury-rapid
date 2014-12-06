require 'ury_rapid/services/service.rb'
require 'ury_rapid/model/structures/playout_model'

module Rapid
  module Examples
    # A fake playout service
    #
    # The FakePlayoutService builds up a model that looks like a playout
    # service, but cannot be controlled.
    #
    # Its configuration DSL exposes the following methods:
    # - 'channels': Takes a list of valid channel IDs.
    class FakePlayoutService < Rapid::Services::Service
      # Initialises the service
      #
      # @api      semipublic
      # @example  Create a new HelloWorldService
      #   service = HelloWorldService.new(view)
      #
      # @param environment [Rapid::Services::Environment]
      #   The Service's environment.
      def initialize(environment)
        # We need to initialise Rapid::Services::Service with the
        # environment
        super(environment)

        # The default channel set, overridden by #channels.
        @channels = {}
      end

      # Runs the service on the EventMachine loop
      #
      # Since we have no EventMachine-bound connections, timers, or I/O tasks,
      # this is empty.
      #
      # @api      public
      # @example  Run the HelloWorldService.
      #   service.run
      #
      # @return [void]
      def run
        # #insert_components is an instance-exec, so this won't be available
        # as an instance variable.
        c = @channels
        pm = Rapid::Model::Structures.playout_model(c)

        environment.insert_components('/') do
          instance_eval(&pm)
        end
      end

      #
      # Begin configuration DSL
      #

      # Sets the list of channel IDs.
      #
      # @api      public
      # @example  Set the channel IDs to ['0', '1', '2', '3']
      #   # In config.rb
      #   channels ['0', '1', '2', '3']
      #
      # @param ids [Array]
      #   The array of channel IDs to use.
      #
      # @return [void]
      attr_writer :channels
      alias_method :channels, :channels=

      #
      # End configuration DSL
      #
    end
  end
end
