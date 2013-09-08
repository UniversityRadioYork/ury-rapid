module Bra
  module Baps
    # Internal: Classes for dealing with BAPS server responses on a structural
    # level.
    #
    # For raw response reading functionality, see baps_client.
    module Responses
      # Creates a response structure for a response returning only a count.
      def self.count(name)
        [name, %i{count uint32}]
      end

      # Creates a response structure for a response returning a configuration
      # setting ID and value.
      def self.config(name)
        [name, %i{option_id uint32}, %i{setting config_setting}]
      end

      STRUCTURES = {
        # Playback
        Codes::Playback::STOP => ['ChannelStopped'],
        Codes::Playback::PAUSE => ['ChannelPaused'],
        Codes::Playback::PLAY => ['ChannelPlaying'],
        Codes::Playback::VOLUME => ['ChannelVolume', %i{volume float32}],
        Codes::Playback::LOADED => [
          'Loaded', %i{index uint32}, %i{type load_body}
        ],
        Codes::Playback::POSITION => ['Position', %i{position uint32}],
        Codes::Playback::CUE => ['Cue', %i{position uint32}],
        Codes::Playback::INTRO => ['Intro', %i{position uint32}],
        # Playlist
        Codes::Playlist::ITEM_COUNT => count('ItemCount'),
        Codes::Playlist::ITEM_DATA => [
          'ItemData',
          %i{index uint32}, %i{type uint32}, %i{title string}
        ],
        Codes::Playlist::RESET => ['Reset'],
        # Config
        Codes::Config::OPTION_COUNT => count('OptionCount'),
        Codes::Config::OPTION => [
          'Option',
          %i{id uint32}, %i{description string}, %i{type uint32}
        ],
        Codes::Config::OPTION_INDEXED => [
          'OptionIndexed',
          %i{id uint32}, %i{description string}, %i{type uint32}
        ],
        Codes::Config::OPTION_CHOICE_COUNT => [
          'OptionChoiceCount',
          %i{option_id uint32}, %i{count uint32}
        ],
        Codes::Config::OPTION_CHOICE => [
          'OptionChoice',
          %i{option_id uint32}, %i{choice_id uint32}, %i{description string}
        ],
        Codes::Config::CONFIG_SETTING_COUNT => count('SettingCount'),
        Codes::Config::CONFIG_SETTING => config('Setting'),
        Codes::Config::CONFIG_SETTING_INDEXED => config('IndexedSetting'),
        # System
        Codes::System::SEED => ['Seed', %i{seed string}],
        Codes::System::LOGIN_RESULT => ['LoginResult', %i{details string}],
        Codes::System::CLIENT_ADD => ['ClientAdd', %i{client string}],
        Codes::System::CLIENT_REMOVE => ['ClientRemove', %i{client string}],
        Codes::System::LOG_MESSAGE => ['LogMessage', %i{message string}]
      }

      class UnknownResponse < StandardError
      end
    end
  end
end
