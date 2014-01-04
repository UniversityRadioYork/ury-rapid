require 'bra/common/exceptions'
require 'bra/driver_common/requests/handler'

module Bra
  module DriverCommon
    module Requests
      class NullHandler < Handler
        def initialize
          super(nil, nil, nil, nil)
        end

        def to_s
          'NO HANDLER'
        end

        def call(action, *args)
          fail(
            Bra::Common::Exceptions::NotSupportedByBra,
            "Tried to perform #{action} on an object with no handler."
          )
        end
      end
    end
  end
end
