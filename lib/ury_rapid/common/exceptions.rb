module Rapid
  module Common
    # General exceptions thrown by Rapid.
    module Exceptions
      # Exception generated when a command is incorrectly invoked.
      CommandError = Class.new(RuntimeError)

      # Exception generated when a resource cannot be found by its URL.
      MissingResource = Class.new(RuntimeError)

      # Exception generated when authentication fails.
      AuthenticationFailure = Class.new(RuntimeError)

      # Exception generated when required privileges are missing.
      InsufficientPrivilegeError = Class.new(RuntimeError)

      # Exception generated when the playout system sends an invalid message.
      InvalidPlayoutResponse = Class.new(RuntimeError)

      # Exception generated when the client gives an invalid payload
      InvalidPayload = Class.new(RuntimeError)

      # Exception generated when errors are found in the user configuration
      BadConfig = Class.new(RuntimeError)

      # Exception generated when the client requests something unsupported
      class NotSupported < RuntimeError
        def to_s
          'Action not supported.'
        end
      end

      # Exception generated when the client requests something unsupported by
      # Rapid.
      class NotSupportedByRapid < NotSupported
        def to_s
          'Action not supported: Not supported by Rapid.'
        end
      end

      # Exception generated when the client requests something that the service
      # cannot support
      class NotSupportedByService < NotSupported
        def to_s
          'Action not supported: Not implemented by service.'
        end
      end

      # Exception generated when the model is improperly configured
      class BadModel < RuntimeError
        def to_s
          'Model is improperly configured.'
        end
      end

      # Exception generated when an update is generated on a model object with
      # no update channel configured
      class MissingUpdateChannel < BadModel
        def initialize(model_object)
          @model_object = model_object
        end

        def to_s
          "Object #{model_object.url} tried to notify an update," \
          'but has no updates channel.'
        end

        attr_reader :model_object
      end
    end
  end
end
