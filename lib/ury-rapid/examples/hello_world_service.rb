require 'ury-rapid/service_common/service.rb'

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
      # @example  Create a new service, given a logger
      #   service = Service.new(logger)
      #
      # @param logger [Object]
      #   An object that can be used to log messages from the service.
      def initialize(logger)
        # We need to initialise Rapid::ServiceCommon::Service with the logger
        # provided.
        super(logger)

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

      private

      # Constructs the sub-model structure for this HelloWorldService
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
        Structure.new(update_channel, logger, @message)
      end

      # The structure used by this HelloWorldService
      #
      # Service structures need not be hidden inside the service class; we just
      # do this for the HelloWorldService as it is such a small structure.
      class Structure < Rapid::Model::Creator
        def initialize(update_channel, logger, message)
          super(update_channel, logger, {})

          @message = message
        end

        # Create the model from the given configuration
        #
        # @api      semipublic
        # @example  Create the model
        #   struct.create
        #
        # @return [Constant]  The finished model.
        def create
          root do
            component :message, :constant, @message, :message
          end
        end
      end
    end
  end
end
