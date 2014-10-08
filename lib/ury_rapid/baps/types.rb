module Rapid
  module Baps
    # Internal: Various type enumerations used in BAPS.
    module Types
      # Public: Enumeration of the codes used by BAPS to refer to configuration
      # parameter types.
      module Config
        INT = 0
        STR = 1
        CHOICE = 2
      end

      # Public: Enumeration of the codes used by BAPS to refer to track types.
      module Track
        VOID = 0
        FILE = 1
        LIBRARY = 2
        TEXT = 3
        SPECIFIC_ITEM = 4
      end
    end
  end
end
