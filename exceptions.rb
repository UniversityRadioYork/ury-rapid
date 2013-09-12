module Bra
  # Public: General exceptions thrown by BRA.
  module Exceptions
    # Public: Exception generated when a command is incorrectly invoked.
    CommandError = Class.new(RuntimeError)
  end
end
