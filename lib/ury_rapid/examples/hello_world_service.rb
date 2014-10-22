require 'ury_rapid/service_common/service.rb'

module Rapid
  module Examples
    # A simple example service
    #
    # The HelloWorldService does nothing except provide a sub-model with one
    # item, a constant called 'message' that shows a programmable message.
    #
    # Its configuration DSL exposes one configurable item, 'message', that
    # overrides the default message ('Hello, World!', of course) with the one
    # provided.
    class HelloWorldService < Rapid::ServiceCommon::Service
      # Initialises the service
      #
      # @api      semipublic
      # @example  Create a new HelloWorldService
      #   service = HelloWorldService.new(view)
      #
      # @param view [Rapid::Model::View]
      #   A view of the Rapid model.
      # @param auth [Object]
      #   An authentication provider.
      def initialize(view)
        # We need to initialise Rapid::ServiceCommon::Service with the
        # arguments provided.
        super(view)

        # The default message, overridden using #message.
        @message = 'Hello, World!'
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
        view.insert_components('/') do
          constant :message, @message, :message
        end
      end

      #
      # Begin configuration DSL
      #

      # Sets the message exposed by this HelloWorldService
      #
      # @api      public
      # @example  Set the message to 'Good Morning, Vietnam!'
      #   # In config.rb
      #   message 'Good Morning, Vietnam!'
      #
      # @param new_message [String]
      #   The message to substitute for the original message.
      #
      # @return [void]
      attr_writer :message
      alias_method :message, :message=

      #
      # End configuration DSL
      #
    end
  end
end
