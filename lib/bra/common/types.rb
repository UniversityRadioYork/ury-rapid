require 'bra/common/exceptions'

module Bra
  module Common
    # Common type enumerations used in bra, as well as validators for those
    # types
    module Types
      PLAY_STATES = %i(playing paused stopped)
      LOAD_STATES = %i(ok empty loading failed)
      TRACK_TYPES = %i(library file text null)
      MARKERS = %i(cue position intro)

      # Validators for the BRA type enumerators.
      module Validators
        %w(play_state load_state track_type).each do |type|
          define_method("validate_#{type}") do |candidate|
            validate_symbol(candidate, Types.const_get("#{type.upcase}S"))
          end
        end

        def validate_symbol(input, range)
          input.to_sym.tap { |symbol| invalid unless range.include?(symbol) }
        end
        module_function :validate_symbol

        def validate_volume(input)
          [0.0, Float(input), 1.0].sort[1]
        end
        module_function :validate_volume

        def validate_marker(input)
          # Why is the input changed to a string?
          # Because Integer('0.3') raises an error, but Integer(0.3) doesn't.
          # Integer('3') and Integer(3), however, both return 3.
          Integer(input.to_s).tap { |marker| invalid if marker < 0 }
        end
        module_function :validate_marker

        def invalid
          fail(Bra::Common::Exceptions::InvalidPayload)
        end
        module_function :invalid
      end
    end
  end
end
