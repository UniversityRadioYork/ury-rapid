require 'ury-rapid/common/exceptions'

module Rapid
  module Baps
    # Exceptions for the BAPS service.
    module Exceptions
      # Exception generated when the playout system sends a load request for a
      # track type Rapid doesn't understand.
      class InvalidTrackType < Rapid::Common::Exceptions::InvalidPlayoutResponse
        def initialize(type)
          super(type)
          @type = type
        end

        def to_s
          "Invalid track type: #{@type}."
        end
      end
    end
  end
end
