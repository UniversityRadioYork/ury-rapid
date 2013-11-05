module Bra
  module Baps
    # Internal: Classes for dealing with BAPS server responses on a structural
    # level.
    #
    # For raw response reading functionality, see baps_client.
    module Responses
      # Pre-defined stock response structures.
      NO_ARGS = []
      COUNT   = [ %i{count uint32} ]
      CONFIG  = [ %i{option_id uint32}, %i{setting config_setting} ]
      MARKER  = [ %i{position uint32} ]
      OPTION  = [ %i{id uint32}, %i{description string}, %i{type uint32} ]

      # Creates a structure with one string argument.
      # 
      # @param arg_name [Symbol] The name of the string argument.
      #
      # @return [Array] The response structure.
      def self.string(arg_name)
        [ [arg_name, :string] ]
      end

      STRUCTURES = {
      # Playback
        Codes::Playback::STOP => NO_ARGS, 
        Codes::Playback::PAUSE => NO_ARGS,
        Codes::Playback::PLAY => NO_ARGS,
        Codes::Playback::VOLUME => [ %i{volume float32} ],
        Codes::Playback::LOADED => [ %i{index uint32}, %i{type load_body} ],
        Codes::Playback::POSITION => MARKER,
        Codes::Playback::CUE      => MARKER,
        Codes::Playback::INTRO    => MARKER,
      # Playlist
        Codes::Playlist::ITEM_COUNT => COUNT,
        Codes::Playlist::ITEM_DATA => [
          %i{index uint32}, %i{type uint32}, %i{title string}
        ],
        Codes::Playlist::RESET => NO_ARGS,
      # Config
        Codes::Config::OPTION_COUNT => COUNT,
        Codes::Config::OPTION => OPTION,
        Codes::Config::OPTION_INDEXED => OPTION,
        Codes::Config::OPTION_CHOICE_COUNT => [
          %i{option_id uint32}, %i{count uint32}
        ],
        Codes::Config::OPTION_CHOICE => [
          %i{option_id uint32}, %i{choice_id uint32}, %i{description string}
        ],
        Codes::Config::CONFIG_SETTING_COUNT   => COUNT,
        Codes::Config::CONFIG_SETTING         => CONFIG,
        Codes::Config::CONFIG_SETTING_INDEXED => CONFIG,
      # System
        Codes::System::SEED          => string(:seed),
        Codes::System::LOGIN_RESULT  => string(:details),
        Codes::System::CLIENT_ADD    => string(:client),
        Codes::System::CLIENT_REMOVE => string(:client),
        Codes::System::LOG_MESSAGE   => string(:message),
      }

      class UnknownResponse < StandardError
      end
    end
  end
end
