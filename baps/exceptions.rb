require_relative '../exceptions'

module Bra
  module Baps
    # Exceptions for the BAPS driver.
    module Exceptions
      # Exception generated when the playout system sends a load request for a
      # track type bra doesn't understand.
      InvalidTrackType = Class.new(Bra::Exceptions::InvalidPlayoutResponseError)
    end
  end
end
