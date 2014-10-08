require 'ury_rapid/common/exceptions'
require 'ury_rapid/service_common/requests/handler'

module Rapid
  module ServiceCommon
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
            Rapid::Common::Exceptions::NotSupportedByRapid,
            "Tried to perform #{action} on an object with no handler."
          )
        end
      end
    end
  end
end
