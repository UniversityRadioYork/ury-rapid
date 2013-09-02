module Bra
  module Responses
    module Playback
      PLAYING = 0x0000
      PAUSED = 0x0010
      STOPPED = 0x0080
      VOLUME = 0x0200
      LOADED = 0x0280
      CUE = 0x0300
      INTRO = 0x0380
    end
    module Playlist
      ITEM_COUNT = 0x2180
      ITEM_DATA = 0x21C0
    end
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
    module System
      SEED = 0xE700
      LOGIN = 0xE900
    end

    class ResponseType
      attr_reader :name

      def initialize(name, *arguments)
        @name = name
        @arguments = arguments
      end

      # Reads a response of this response type from the given BAPS reader, and
      # packs it into a hash of response parameters.
      def build(reader)
        @arguments.inject({:name => @name}) do |response, (name, type)|
          response.merge!(name => (reader.send type))
        end
      end

      # Creates a response structure for a response returning only a count.
      def self.count(name)
        [name, %i{count uint32}]
      end

      # Creates a response structure for a response returning a configuration
      # setting ID and value.
      def self.config(name)
        ['ConfigSetting', %i{option_id uint32}, %i{setting config_setting}]
      end
    end



    STRUCTURES = {
      # Playback
      Playback::STOPPED => ['ChannelStopped'],
      Playback::PAUSED => ['ChannelPaused'],
      Playback::PLAYING => ['ChannelPlaying'],
      Playback::VOLUME => [
        'ChannelVolume',
        %i{volume float32}
      ],
      Playback::LOADED => [
        'ChannelLoaded',
        %i{index uint32}, %i{type uint32}, %i{name string}, %i{duration uint32}
      ],
      Playback::CUE => [
        'ChannelCue',
        %i{position uint32}
      ],
      Playback::INTRO => [
        'ChannelIntro',
        %i{position uint32}
      ],
      # Playlist
      Playlist::ITEM_COUNT => (ResponseType::count 'ItemCount'),
      Playlist::ITEM_DATA => [
        'ItemData',
        %i{index uint32}, %i{type uint32}, %i{name string}
      ],
      # Config
      Config::OPTION_COUNT => (ResponseType::count 'OptionCount'),
      Config::OPTION => [
        'Option',
        %i{id uint32}, %i{description string}, %i{type uint32}
      ],
      Config::OPTION_INDEXED => [
        'OptionIndexed',
        %i{id uint32}, %i{description string}, %i{type uint32}
      ],
      Config::OPTION_CHOICE_COUNT => [
        'OptionChoiceCount',
        %i{option_id uint32}, %i{count uint32}
      ],
      Config::OPTION_CHOICE => [
        'OptionChoice',
        %i{option_id uint32}, %i{choice_id uint32}, %i{description string}
      ],
      Config::CONFIG_SETTING_COUNT => ResponseType::count('SettingCount'),
      Config::CONFIG_SETTING => ResponseType::config('Setting'),
      Config::CONFIG_SETTING_INDEXED => ResponseType::config('IndexedSetting'),
      # System
      System::SEED => ['Seed', %i{seed string}],
      System::LOGIN => ['Login', %i{details string}],
      # Playlist
      Playlist::ITEM_COUNT => (ResponseType::count 'ItemCount'),
      Playlist::ITEM_DATA => [
        'ItemData',
        %i{index uint32}, %i{type uint32}, %i{name string}
      ],
    }

    class UnknownResponse < StandardError
    end

    class Source
      def initialize(reader)
        @reader = reader

        @structure_hash = STRUCTURES.inject({}) do |hash, (code, arguments)|
          hash.merge!(code => ResponseType.new(*arguments))
        end
      end

      def read_response
        raw_code, skip_bytes = @reader.command

        code, subcode = raw_code & 0xFFF0, raw_code & 0x000F

        # We could use skip_bytes to skip an unknown message, but BAPS is quite
        # dodgy at implementing this in places, so we don't do it.
        raise UnknownResponse, code.to_s(16) unless @structure_hash.key? code

        response = { :code => code, :subcode => subcode }
        response.merge!(@structure_hash[code].build @reader)
      end
    end
  end
end
