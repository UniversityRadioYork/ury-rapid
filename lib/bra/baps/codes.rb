require 'bra/driver_common/code_table'

module Bra
  module Baps
    # Internal BAPS codes for requests and responses
    #
    # The BAPS codes are segmented, both in the concrete code space and in this
    # module, into various groups.
    #
    # For the format of responses from the BAPS server, see
    # Bra::Baps::Responses::Structures.
    module Codes
      extend Bra::DriverCommon::CodeTable

      # Response codes for the Playback section of the BAPS command set
      module Playback
        PLAY     = 0x0000
        STOP     = 0x0080
        PAUSE    = 0x0100
        POSITION = 0x0180
        VOLUME   = 0x0200
        LOAD     = 0x0280
        CUE      = 0x0300
        INTRO    = 0x0380
      end

      # Response codes for the Playlist section of the BAPS command set
      module Playlist
        ADD_ITEM              = 0x2000 # Request only
        DELETE_ITEM           = 0x2080
        MOVE_ITEM_IN_PLAYLIST = 0x2100
        ITEM_COUNT            = 0x2180 # Response only
        ITEM_DATA             = 0x21C0 # Response only
        GET                   = 0x2200 # Unused
        RESET                 = 0x2280
        COPY_ITEM_TO_PLAYLIST = 0x2300 # Request only
      end

      # Response codes for the Database section of the BAPS command set
      module Database
        LIBRARY_SEARCH   = 0x6000 # Request only, except a rare buggy response
        LIBRARY_ORDERING = 0x6100 # Request only
        LIBRARY_RESULT   = 0x6200 # Response only
        LIBRARY_ERROR    = 0x6300 # Response only
        GET_SHOWS        = 0x6400 # Request only, unused
        SHOW_COUNT       = 0x6500 # Response only
        SHOW             = 0x6580 # Response only
        GET_LISTINGS     = 0x6600 # Request only, unused
        LISTING_COUNT    = 0x6700 # Response only
        LISTING          = 0x6780 # Response only
        ASSIGN_LISTING   = 0x6800 # Request only
        DATABASE_ERROR   = 0x6900 # Response only
      end

      # Response codes for the Config section of the BAPS command set
      module Config
        GET_OPTIONS            = 0xA000
        GET_OPTION_CHOICES     = 0xA100
        GET_CONFIG_SETTINGS    = 0xA200
        GET_CONFIG_SETTING     = 0xA300
        GET_OPTION             = 0xA400
        SET_CONFIG_VALUE       = 0xA500
        GET_USERS              = 0xA600
        GET_PERMISSIONS        = 0xA700
        GET_USER               = 0xA800
        ADD_USER               = 0xA900
        REMOVE_USER            = 0xAA00
        SET_PASSWORD           = 0xAB00
        GRANT_PERMISSION       = 0xAC00
        REVOKE_PERMISSION      = 0xAD00
        OPTION_COUNT           = 0xB000
        OPTION                 = 0xB080
        OPTION_INDEXED         = 0xB0C0
        OPTION_CHOICE_COUNT    = 0xB100
        OPTION_CHOICE          = 0xB180
        OPTION_CHOICE_INDEXED  = 0xB1C0
        CONFIG_SETTING_COUNT   = 0xB200
        CONFIG_SETTING         = 0xB280
        CONFIG_SETTING_INDEXED = 0xB2C0
        USER                   = 0xB300
        PERMISSION             = 0xB400
        USER_RESULT            = 0xB500
        CONFIG_RESULT          = 0xB600
        CONFIG_ERROR           = 0xB700
        GET_IP_RESTRICTIONS    = 0xB800
        IP_RESTRICTION         = 0xB900
        ADD_IP_ALLOW           = 0xBA00
        ADD_IP_DENY            = 0xBA40
        REMOVE_IP_ALLOW        = 0xBA80
        REMOVE_IP_DENY         = 0xBAC0
      end

      # Response codes for the System section of the BAPS command set
      module System
        # The welcome message isn't a real command, but we want to treat it
        # like one.
        WELCOME_MESSAGE = :welcome_message
        LIST_FILES      = 0xE000 # Request only
        FILE_COUNT      = 0xE100
        FILE            = 0xE1C0
        SEND_MESSAGE    = 0xE200
        SYNC            = 0xE300
        END_SESSION     = 0xE400
        LOG_MESSAGE     = 0xE500
        SET_BINARY_MODE = 0xE600
        SEED            = 0xE700
        LOGIN           = 0xE800
        LOGIN_RESULT    = 0xE900
        VERSION         = 0xEA00
        SEND_FEEDBACK   = 0xEB00
        CLIENT_CHANGE   = 0xEC00
        SCROLL_TEXT     = 0xED00
        TEXT_SIZE       = 0xEE00
      end
    end
  end
end
