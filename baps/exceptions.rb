require_relative '../exceptions'

module Bra
  module Baps
    # Exceptions for the BAPS driver.
    module Exceptions
      # Exception generated when the playout system sends a load request for a
      # track type bra doesn't understand.
      class InvalidTrackType < Bra::Exceptions::InvalidPlayoutResponseError
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
