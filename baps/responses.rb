module Bra
  module Baps
    # Structures for BAPS responses
    #
    # In order to be able to parse responses from the BAPS client into a format
    # that can be read by the controller, we need to know their structure
    # (which parameters they take, and in which order).
    #
    # The Responses module defines each response known to the BAPS driver (out
    # of necessity; if the driver receives a response it doesn't know, the
    # driver cannot parse the rest of the stream and dies), as well as its
    # parameters in order of receipt and their corresponding names in the
    # response hashes produced by the ResponseParser.
    module Responses
      # Pre-defined stock response structures.
      NO_ARGS = []
      COUNT   = [ %i{count uint32} ]
      CONFIG  = [ %i{option_id uint32}, %i{setting config_setting} ]
      MARKER  = [ %i{position uint32} ]
      OPTION  = [ %i{id uint32}, %i{description string}, %i{type uint32} ]
      INDEX   = [ %i{index uint32} ]

      STRUCTURES = {
      # Playback
        Codes::Playback::STOP     => NO_ARGS, 
        Codes::Playback::PAUSE    => NO_ARGS,
        Codes::Playback::PLAY     => NO_ARGS,
        Codes::Playback::VOLUME   => [ %i{volume float32} ],
        Codes::Playback::LOADED   => [ %i{index uint32}, %i{type load_body} ],
        Codes::Playback::POSITION => MARKER,
        Codes::Playback::CUE      => MARKER,
        Codes::Playback::INTRO    => MARKER,

      # Playlist
        Codes::Playlist::DELETE_ITEM => INDEX,
        Codes::Playlist::ITEM_COUNT  => COUNT,
        Codes::Playlist::ITEM_DATA   => [
          %i{index uint32}, %i{type uint32}, %i{title string}
        ],
        Codes::Playlist::RESET       => NO_ARGS,

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

      private

      # Creates a structure with one string argument.
      #
      # @api private
      # 
      # @param arg_name [Symbol] The name of the string argument.
      #
      # @return [Array] The response structure.
      def self.string(arg_name)
        [ [arg_name, :string] ]
      end


    end
  end
end
