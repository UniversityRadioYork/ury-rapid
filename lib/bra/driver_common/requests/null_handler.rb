require 'bra/common/exceptions'
require 'bra/driver_common/requests/handler'

module Bra
  module DriverCommon
    module Requests
      # Null-object for request handling
      #
      # This handler is intended to be used when no other handler is
      # registered.
      class NullHandler < Handler
        def initialize
          super(nil, nil, nil, nil)
        end

        def to_s
          'NO HANDLER'
        end

        def call(action, *_args)
          fail(
            Bra::Common::Exceptions::NotSupportedByBra,
            "Tried to perform #{action} on an object with no handler."
          )
        end
      end
    end
  end
end
