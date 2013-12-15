module Bra
  # General exceptions thrown by bra.
  module Exceptions
    # Exception generated when a command is incorrectly invoked.
    CommandError = Class.new(RuntimeError)

    # Exception generated when a resource cannot be found by its URL.
    MissingResourceError = Class.new(RuntimeError)

    # Exception generated when authentication fails.
    AuthenticationFailure = Class.new(RuntimeError)

    # Exception generated when required privileges are missing.
    InsufficientPrivilegeError = Class.new(RuntimeError)

    # Exception generated when the playout system sends an invalid message.
    InvalidPlayoutResponseError = Class.new(RuntimeError)

    # Exception generated when the client gives an invalid payload
    InvalidPayload = Class.new(RuntimeError)

    # Exception generated when the client requests something unsupported
    class NotSupported < RuntimeError
      def to_s
        'Action not supported.'
      end
    end

    # Exception generated when the client requests something unsupported by
    # bra.
    class NotSupportedByBra < NotSupported
      def to_s
        'Action not supported: Not supported by bra.'
      end
    end

    # Exception generated when the client requests something that the driver
    # cannot support
    class NotSupportedByDriver < NotSupported
      def to_s
        'Action not supported: Not implemented by driver.'
      end
    end
  end
end
