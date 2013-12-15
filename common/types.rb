module Bra
  module Common
    # Common type enumerations used in bra, as well as validators for those
    # types
    module Types
      PLAY_STATES = %i{playing paused stopped}
      LOAD_STATES = %i{ok empty loading failed}
      TRACK_TYPES = %i{library file text null}
      MARKERS = %i{cue position intro duration}

      def self.validate_play_state(candidate)
        validate_symbol(candidate, PLAY_STATES)
      end

      def self.validate_load_state(candidate)
        validate_symbol(candidate, LOAD_STATES)
      end

      def self.validate_track_type(candidate)
        validate_symbol(candidate, TRACK_TYPES)
      end

      def self.validate_symbol(candidate, range)
        # TODO: convert strings to symbols
        symbol = candidate.to_sym
        fail(InvalidPayload) unless range.include?(symbol)
        symbol
      end
    end
  end
end
