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
      end
    end
  end
end
