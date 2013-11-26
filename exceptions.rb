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
  end
end
