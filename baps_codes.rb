module Bra
  # Internal: Internal BAPS codes for requests and responses.
  module BapsCodes
    # Internal: Response codes for the Playback section of the BAPS command
    # set.
    module Playback
      PLAYING = 0x0000
      STOPPED = 0x0080
      PAUSED = 0x0100
      POSITION = 0x0180
      VOLUME = 0x0200
      LOADED = 0x0280
      CUE = 0x0300
      INTRO = 0x0380
    end

    # Internal: Response codes for the Playlist section of the BAPS command
    # set.
    module Playlist
      ITEM_COUNT = 0x2180
      ITEM_DATA = 0x21C0
    end

    # Internal: Response codes for the Config section of the BAPS command
    # set.
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

    # Internal: Response codes for the System section of the BAPS command
    # set.
    module System
      # The welcome message isn't a real command, but we want to treat it like
      # one.
      WELCOME_MESSAGE = :welcome_message
      SYNC = 0xE300
      SET_BINARY_MODE = 0xE600
      SEED = 0xE700
      LOGIN = 0xE800
      LOGIN_RESULT = 0xE900
      CLIENT_ADD = 0xEC00
      CLIENT_REMOVE = 0xEC80
    end
  end
end
