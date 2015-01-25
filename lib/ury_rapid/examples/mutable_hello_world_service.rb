require 'ury_rapid/examples/hello_world_service'
require 'ury_rapid/services/service'
require 'ury_rapid/services/requests/handler'
require 'ury_rapid/model/constant'

module Rapid
  module Examples
    # A hello world service supporting PUT and DELETE requests
    #
    # The MutableHelloWorldService does everything HelloWorldService does,
    # except it also allows the message to be 'put' to with a string
    # (overwriting the message), or 'delete'd (setting the string back to its
    # original value).
    class MutableHelloWorldService < Rapid::Examples::HelloWorldService
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
        msg = Rapid::Model::Constant.new(:message, @message)
        msg.register_handler(MessageHandler.new(@message))
        environment.insert('/', :message, msg)
      end
    end

    # An example of a simple Handler that handles PUT/DELETE on the message.
    #
    # Most Handlers are far more complex than this, so Rapid has a large
    # library of helper classes and DSLs to make writing Handlers easier.
    # See the Rapid::Services::[Requests/Responses]::Handler classes.
    class MessageHandler
      def initialize(message)
        @original_message = message
      end

      # Handle a DELETE by setting the message back to its original value
      #
      # @param model_object [ModelObject]
      #   The message Constant, which just got told to DELETE itself.
      # @param payload [Payload]
      #   The payload of the DELETE, which is ignored (and should be empty).
      #
      # @return [void]
      def delete(model_object, payload)
        MessageSetter.new(model_object, self).string(@original_message)
      end

      # Handle a PUT by replacing the message
      #
      # @param model_object [ModelObject]
      #   The message Constant, which just got told to PUT itself.
      # @param payload [Payload]
      #   The payload of the PUT, which should be a string contianing the new
      #   value.
      #
      # @return [void]
      def put(model_object, payload)
        # This causes the payload to try and parse itself.  If it is a valid
        # string, it'll call the given object back at #string.
        # See Rapid::Common::Payload for more information.
        payload.process(MessageSetter.new(model_object, self))
      end

      # Method object (ish) responsible for setting the message.
      #
      # The split between this and its parent class is largely due to how the
      # Payload calls us back.  Since it only passes us a #string with one
      # argument (the parsed payload string), we need to hold onto the model
      # object, which we do by wrapping it in this class.
      class MessageSetter
        # Construct a new MessageSetter
        #
        # @param model_object [ModelObject]
        #   The message Constant, which will be updated by this object.
        # @param handler [MessageHandler]
        #   The parent handler.
        def initialize(model_object, handler)
          @model_object = model_object
          @handler      = handler
        end

        # Handle an incoming request to change the message to a given string
        #
        # @param new_message [String]
        #   The new message.
        # @return [void]
        def string(new_message)
          # We replace the string by replacing the entire model object.
          # This seems drastic, but simplifies things in the long-run.

          msg = Rapid::Model::Constant.new(:message, @message)
          msg.register_handler(@handler)
          @model_object.replace(msg)
        end
      end
    end
  end
end
