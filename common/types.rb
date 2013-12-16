module Bra
  module Common
    # Common type enumerations used in bra, as well as validators for those
    # types
    module Types
      PLAY_STATES = %i{playing paused stopped}
      LOAD_STATES = %i{ok empty loading failed}
      TRACK_TYPES = %i{library file text null}
      MARKERS = %i{cue position intro duration}

      # Validators for the BRA type enumerators.
      module Validators
        %w{play_state load_state track_type}.each do |type|
          define_method("validate_#{type}") do |candidate|
            validate_symbol(candidate, Types.const_get("#{type.upcase}S"))
          end
        end

        def validate_symbol(candidate, range)
          # TODO: convert strings to symbols
          symbol = candidate.to_sym
          fail(InvalidPayload) unless range.include?(symbol)
          symbol
        end
      end
    end
  end
end
