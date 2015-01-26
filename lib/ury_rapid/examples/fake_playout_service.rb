require 'ury_rapid/services/service.rb'
require 'ury_rapid/model/components/playout_model'

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
        # Rapid contains a class for quickly building bits of playout model,
        # attaching handlers and an update channel to them on the way.
        # We use this to create the playout service model very quickly.
        pm = Rapid::Model::Components::PlayoutModel.new(
          environment.update_channel,
          {}
        )

        # Since this is a read-only service, we don't register any handlers.
        # But, if we did, they would be added into the empty hash above.
        # Said callbacks are passed pm, making them able to attach handlers
        # that construct or replace model objects using its services.

        environment.insert('/', :channels, pm.channel_set_tree(@channels))
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
