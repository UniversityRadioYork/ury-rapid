module Bra
  module Baps
    # Internal BAPS codes for requests and responses.
    #
    # Also includes methods for handling them.
    #
    # The BAPS codes are segmented, both in the concrete code space and in this
    # module, into various groups.
    module Codes
      # Given a BAPS code, return a vaguely descriptive textual description
      #
      # This is mainly intended for debugging and logging purposes, and is
      # wholly inadequate for user-facing code.  You have been warned!
      #
      # @api semipublic
      #
      # @example Find the name of a BAPS code.
      #   Bra::Baps::Codes.code_symbol(Bra::Baps::Codes::Playback::PLAY)
      #   #=> "Bra::Baps::Codes::Playback::PLAY"
      #
      # @param code [Integer] One of the codes from Bra::Baps::Codes.
      #
      # @return [String] The (semi) human-readable name for the BAPS code.
      def self.code_symbol(code)
        # Assume that the only constants defined in Codes are code groups...
        submodules = constants.map(&method(:const_get))
        # ...and the only constants defined in code groups are codes, and they
        # are disjoint.
        found = nil
        submodules.each do |submodule|
          consts = submodule.constants
          unless found
            found = (
              consts.find { |name| submodule.const_get(name) == code }
              .try { |name| "#{submodule.to_s}::#{name}" }
            )
          end
        end
        fail("Unknown code number: #{code.to_s(16)}") unless found
        found
      end

      # Response codes for the Playback section of the BAPS command set
      module Playback
        PLAY = 0x0000
        STOP = 0x0080
        PAUSE = 0x0100
        POSITION = 0x0180
        VOLUME = 0x0200
        LOADED = 0x0280
        CUE = 0x0300
        INTRO = 0x0380
      end

      # Response codes for the Playlist section of the BAPS command set
      module Playlist
        DELETE_ITEM = 0x2080
        ITEM_COUNT = 0x2180
        ITEM_DATA = 0x21C0
        RESET = 0x2280
      end

      # Response codes for the Config section of the BAPS command set
      module Config
        OPTION_COUNT = 0xB000
        OPTION = 0xB080
        OPTION_INDEXED = 0xB0C0
        OPTION_CHOICE_COUNT = 0xB100
        OPTION_CHOICE = 0xB180
        OPTION_CHOICE_INDEXED = 0xB1C0
        CONFIG_SETTING_COUNT = 0xB200
        CONFIG_SETTING = 0xB280
        CONFIG_SETTING_INDEXED = 0xB2C0
      end

      # Response codes for the System section of the BAPS command set
      module System
        # The welcome message isn't a real command, but we want to treat it
        # like one.
        WELCOME_MESSAGE = :welcome_message
        SYNC = 0xE300
        LOG_MESSAGE = 0xE500
        SET_BINARY_MODE = 0xE600
        SEED = 0xE700
        LOGIN = 0xE800
        LOGIN_RESULT = 0xE900
        CLIENT_ADD = 0xEC00
        CLIENT_REMOVE = 0xEC80
      end
    end
  end
end
