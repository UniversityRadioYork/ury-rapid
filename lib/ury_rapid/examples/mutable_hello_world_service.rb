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
        msg.register_handler(
          proc do |action, model_object, payload|
            # We have a MessageSetter class to do the actual setting.
            # We pass it the model object's handler, so that any replacements
            # of said object keep the same handler.
            setter = MessageSetter.new(model_object, model_object.handler)

            # We here match upon the action that triggered the handler:
            case action
              when :put
                # Set the message to whatever comes out of the payload.
                # See Rapid::Common::Payload for more information.
                payload.process(setter)
              when :delete
                # Set the message back to its original.
                setter.string(@message)
              else
                fail(Rapid::Common::Exceptions::NotSupportedByService)
            end
          end
        )
        environment.insert('/', :message, msg)
      end
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

      # Handle an incoming request to change the message, via a hash
      #
      # Since JSON doesn't allow raw strings, sometimes the message will
      # come in wrapped in a JSON object.  The payload processor will
      # then call this instead of #string.
      #
      # The ignored first argument is the :type key, if any.  This is useful
      # for certain specific handlers, but not for us.
      #
      # @param new_message [Array]
      #   The new message, as a hash.
      #
      # @return [void]
      def hash(_, new_message)
        # TODO(mattbw): Refactor payloads so it's possible to send a string
        # with some sort of uniform wrapping, perhaps
        fail(
          Rapid::Common::Exceptions::BadPayload,
          "needs a 'message' key"
        ) unless new_message.key?(:message)

        string(new_message[:message])
      end

      # Handle an incoming request to change the message to a given string
      #
      # @param new_message [String]
      #   The new message.
      # @return [void]
      def string(new_message)
        # We replace the string by replacing the entire model object.
        # This seems drastic, but simplifies things in the long-run.

        msg = Rapid::Model::Constant.new(:message, new_message)
        msg.register_handler(@handler)
        @model_object.replace(msg)
      end
    end
  end
end
