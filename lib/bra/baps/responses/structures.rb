require 'bra/driver_common/responses/structure_builder'

module Bra
  module Baps
    module Responses
      # Structures for BAPS responses
      #
      # In order to be able to parse responses from the BAPS client into a
      # format that can be read by the controller, we need to know their
      # structure (which parameters they take, and in which order).
      #
      # The Responses module defines each response known to the BAPS driver
      # (out of necessity; if the driver receives a response it doesn't know,
      # the driver cannot parse the rest of the stream and dies), as well as
      # its parameters in order of receipt and their corresponding names in the
      # response hashes produced by the response parser.
      module Structures
        extend Bra::DriverCommon::Responses::StructureBuilder

        # These are the types used in BAPS, and correspond to the types used
        # in the response parser.
        def_types :float32, :uint32, :string, :load_body, :config_setting

        # Some common arguments
        def_argument_shortcuts :uint32, %i(position count index)
        def_argument_shortcuts :uint32, %i(old_index new_index)
        def_argument_shortcuts :uint32, %i(id choice_id option_id)
        def_argument_shortcuts :string, %i(title description message client)

        def_struct :unary
        def_struct :marker, position
        def_struct :config, option_id, config_setting(:setting)
        def_struct :option, id, description, uint32(:type)

        structures do
          group Codes::Playback do
            unary PLAY
            unary STOP
            unary PAUSE
            marker POSITION
            struct VOLUME, float32(:volume)
            struct LOAD,   index, load_body(:type)
            marker CUE
            marker INTRO
          end
          group Codes::Playlist do
            # ADD_ITEM is request only
            struct DELETE_ITEM,           index
            struct MOVE_ITEM_IN_PLAYLIST, old_index, new_index
            struct ITEM_COUNT,            count
            struct ITEM_DATA,             index, uint32(:type), title
            # GET is unused
            unary RESET
            # COPY_ITEM_TO_PLAYLIST is request only
          end
          group Codes::Config do
            struct OPTION_COUNT,         count
            struct OPTION_CHOICE_COUNT,  option_id, count
            struct OPTION_CHOICE,        option_id, choice_id, description
            struct CONFIG_SETTING_COUNT, count

            option OPTION, OPTION_INDEXED
            config CONFIG_SETTING, CONFIG_SETTING_INDEXED
          end
          group Codes::System do
            struct SEED,          string(:seed)
            struct LOGIN_RESULT,  string(:details)
            struct CLIENT_CHANGE, client
            struct LOG_MESSAGE,   string(:message)
          end
        end
      end
    end
  end
end
