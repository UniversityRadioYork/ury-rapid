module Bra
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
      BapsCodes::Playback::STOP => ['ChannelStopped'],
      BapsCodes::Playback::PAUSE => ['ChannelPaused'],
      BapsCodes::Playback::PLAY => ['ChannelPlaying'],
      BapsCodes::Playback::VOLUME => ['ChannelVolume', %i{volume float32}],
      BapsCodes::Playback::LOADED => [
        'Loaded', %i{index uint32}, %i{type load_body}
      ],
      BapsCodes::Playback::POSITION => ['Position', %i{position uint32}],
      BapsCodes::Playback::CUE => ['Cue', %i{position uint32}],
      BapsCodes::Playback::INTRO => ['Intro', %i{position uint32}],
      # Playlist
      BapsCodes::Playlist::ITEM_COUNT => count('ItemCount'),
      BapsCodes::Playlist::ITEM_DATA => [
        'ItemData',
        %i{index uint32}, %i{type uint32}, %i{title string}
      ],
      # Config
      BapsCodes::Config::OPTION_COUNT => count('OptionCount'),
      BapsCodes::Config::OPTION => [
        'Option',
        %i{id uint32}, %i{description string}, %i{type uint32}
      ],
      BapsCodes::Config::OPTION_INDEXED => [
        'OptionIndexed',
        %i{id uint32}, %i{description string}, %i{type uint32}
      ],
      BapsCodes::Config::OPTION_CHOICE_COUNT => [
        'OptionChoiceCount',
        %i{option_id uint32}, %i{count uint32}
      ],
      BapsCodes::Config::OPTION_CHOICE => [
        'OptionChoice',
        %i{option_id uint32}, %i{choice_id uint32}, %i{description string}
      ],
      BapsCodes::Config::CONFIG_SETTING_COUNT => count('SettingCount'),
      BapsCodes::Config::CONFIG_SETTING => config('Setting'),
      BapsCodes::Config::CONFIG_SETTING_INDEXED => config('IndexedSetting'),
      # System
      BapsCodes::System::SEED => ['Seed', %i{seed string}],
      BapsCodes::System::LOGIN_RESULT => ['LoginResult', %i{details string}],
      BapsCodes::System::CLIENT_ADD => ['ClientAdd', %i{client string}],
      BapsCodes::System::CLIENT_REMOVE => ['ClientRemove', %i{client string}]
    }

    class UnknownResponse < StandardError
    end
  end
end
