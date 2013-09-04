module Bra
  # Internal: Classes for dealing with BAPS server responses on a structural
  # level.
  #
  # For raw response reading functionality, see baps_client.
  module Responses
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
      SEED = 0xE700
      LOGIN = 0xE900
      CLIENT_ADD = 0xEC00
      CLIENT_REMOVE = 0xEC80
    end

    # Internal: A class representing compiled response types.
    #
    # A response type
    class ResponseType
      attr_reader :name

      # Internal: Initialise a ResponseType.
      #
      # code       - The BAPS base response code of this response; this should
      #              have its last hex digit (subcode) set to 0, and be an
      #              integer.
      # name       - A human-readable name for this response type, for use in
      #              debugging and logging.
      # parameters - A list of pairs of symbols, mapping response parameter
      #              names to their types.
      def initialize(code, name, *parameters)
        @code = code
        @name = name
        @parameters = parameters
      end

      # Internal: Given a subcode and a list of arguments to this response,
      # pack them into a hash of response parameters.
      #
      # subcode   - The sub-code (for example, channel number) that this
      #             response carries.  This can be 0 if there is no subcode.
      # arguments - A list of arguments, in the same order as those in the
      #             response list's parameters list.
      def build(subcode, *arguments)
        @parameters.reduce({ name: @name }) do |response, (name, type)|
          response.merge!(name => (reader.send type))
        end
      end

      # Internal: Generate a list of the types of the parameters this
      # response type expects, in the order in which they should be presented
      # to build.
      #
      # Returns a list as described above.
      def types
        @parameters.map { |_, type| type }
      end

      # Creates a response structure for a response returning only a count.
      def self.count(name)
        [name, %i{count uint32}]
      end

      # Creates a response structure for a response returning a configuration
      # setting ID and value.
      def self.config(name)
        [name, %i{option_id uint32}, %i{setting config_setting}]
      end
    end

    STRUCTURES = {
      # Playback
      Playback::STOPPED => ['ChannelStopped'],
      Playback::PAUSED => ['ChannelPaused'],
      Playback::PLAYING => ['ChannelPlaying'],
      Playback::VOLUME => ['ChannelVolume', %i{volume float32}],
      Playback::LOADED => ['Loaded', %i{index uint32}, %i{track load_body}],
      Playback::POSITION => ['Position', %i{position uint32}],
      Playback::CUE => ['Cue', %i{position uint32}],
      Playback::INTRO => ['Intro', %i{position uint32}],
      # Playlist
      Playlist::ITEM_COUNT => (ResponseType.count 'ItemCount'),
      Playlist::ITEM_DATA => [
        'ItemData',
        %i{index uint32}, %i{type uint32}, %i{track string}
      ],
      # Config
      Config::OPTION_COUNT => (ResponseType.count 'OptionCount'),
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
      Config::CONFIG_SETTING_COUNT => ResponseType.count('SettingCount'),
      Config::CONFIG_SETTING => ResponseType.config('Setting'),
      Config::CONFIG_SETTING_INDEXED => ResponseType.config('IndexedSetting'),
      # System
      System::SEED => ['Seed', %i{seed string}],
      System::LOGIN => ['Login', %i{details string}],
      System::CLIENT_ADD => ['ClientAdd', %i{client string}],
      System::CLIENT_REMOVE => ['ClientRemove', %i{client string}]
    }

    class UnknownResponse < StandardError
    end

    # Internal: An EventMachine connection handler that


    # Internal: An interpreter that reads and converts raw command data from
    # the BAPS server into response messages.
    class Parser
      # Internal: Initialises the Parser.
      #
      # dispatch - The target of completed responses.
      # reader   - An object that can convert raw buffered data to BAPS
      #            meta-protocol tokens.
      def initialize(dispatch, reader)
        @dispatch = dispatch
        @reader = reader

        # Set up to expect the welcome message
        @expected = [%i{message string}]
        @response = {
          name: 'WelcomeMessage',
          code: System::WELCOME_MESSAGE,
          subcode: 0
        }
      end

      # Internal: Read and interpret a response from the BAPS server.
      def receive_data(data)
        @reader.add data

        sufficient_data = true
        while sufficient_data
          sufficient_data = process_next_token
        end
      end

      # Internal: Attempt to process the top of the buffer as part of a
      # response.
      def process_next_token
        command if @response == nil
        word unless @response == nil
      end

      # Internal: Attempt to scrape a command word off the top of the buffer.
      # If successful, the parser then interprets the word and sets up to
      # parse the rest of the command phrase.
      #
      # Returns a boolean specifying whether there was enough data to process
      #   a command word or not.
      def command
        raw_code, _ = @reader.command
        if raw_code then
          code, subcode = raw_code & 0xFFF0, raw_code & 0x000F

          # We could use the second return from reader.command to skip an
          # unknown message, but BAPS is quite dodgy at implementing this in
          # places, so we don't do it.
          raise UnknownResponse, code.to_s(16) unless STRUCTURES.key? code

          name, *@expected = STRUCTURES[code]
          @response = {
            name: name,
            code: code,
            subcode: subcode
          }
        end

        !raw_code.nil?
      end

      # Internal: Attempt to scrape an argument word off the top of the buffer.
      # If there are no arguments left, the parser is set back into command
      # reading mode and the completed response is sent to the dispatch.
      #
      # Returns a boolean specifying whether there was enough data to process
      #   a data word or not.
      def word
        if @expected.empty?
          # We've finished reading the response, so we need to get ready for
          # the next one.
          @dispatch.emit @response
          @response = nil

          true
        else
          # We still need to read a word
          word_description = @expected.shift
          name, arg_type, *args = word_description

          # Some command words can be read from the buffer directly, whereas
          # the parser has its own logic for the more complex ones.
          success = (
            if respond_to? arg_type
              send arg_type, name, *args
            else
              data = @reader.send arg_type, *args
              @response[name] = data unless data.nil?
              !data.nil?
            end
          )

          @expected.unshift word_description unless success
          success
        end
      end

      # Internal: Reads a string.
      def string(name)
        length = @reader.uint32
        @expected.unshift [name, :raw_bytes, length] unless length.nil?
        !length.nil?
      end

      # Internal: Reads a config setting.
      #
      # Config settings are one of the uglier areas of BAPS's meta-protocol,
      # as the format of the config value depends on the preceding config
      # type. As such, it's much easier to treat them specially in the
      # parser.
      #
      # This command only parses the setting type itself; it pushes the
      # correct type for the value into @expected as the next argument.
      #
      # name - The name (as a symbol) of the argument to which the track
      #        type is bound.
      #
      # Returns a boolean specifying whether there was enough data to process
      #   the config type or not.
      def config_setting(name)
        config_type = @reader.uint32
        if config_type.nil? then
          false
        else
          @expected.unshift [:value, CONFIG_TYPE_MAP[config_type]]
          @response[name] = config_type
          true
        end
      end

      # Internal: Reads the body of a LOAD command.
      #
      # LOAD commands change their format depending on the track type, so we
      # have to parse them specially.
      #
      # This command only parses the loaded item type itself; it pushes the
      # correct arguments for each item type into @expected as the arguments
      # immediately following this one.
      #
      # name - The name (as a symbol) of the argument to which the track
      #        type is bound.
      #
      # Returns a boolean specifying whether there was enough data to process
      #   the track type or not.
      def load_body(name)
        track_type = @reader.uint32
        if track_type.nil? then
          false
        else
          # Note that these are in reverse order, as they're being shifted
          # onto the front.
          @expected.unshift DURATION if track_type == TrackTypes::LIBRARY
          @expected.unshift TITLE

          @response[name] = track_type
          true
        end
      end

      # Internal: A map of configuration types to their meta-protocol types.
      # functions for reading them.
      CONFIG_TYPE_MAP = {
        ConfigTypes::CHOICE => :uint32,
        ConfigTypes::INT => :uint32,
        ConfigTypes::STR => :string
      }

      DURATION = %i{duration uint32}
      TITLE = %i{title string}
    end
  end
end
