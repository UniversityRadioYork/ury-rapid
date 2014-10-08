require 'active_support/core_ext/object/try'

require 'ury_rapid/baps/codes'
require 'ury_rapid/baps/responses/command_word'
require 'ury_rapid/baps/responses/structures'
require 'ury_rapid/baps/types'
require 'ury_rapid/common/exceptions'

module Rapid
  module Baps
    module Responses
      # An interpreter that reads and converts raw command data from the BAPS
      # server into response messages.
      #
      # The Parser sits between the Reader, which buffers and allows access to
      # raw BAPS protocol values, and the responses channel, which takes
      # completed response messages and sends them to the Responder.
      class Parser
        # Initialises this Parser
        #
        # @api      semipublic
        # @example  Initialising a response parser
        #   channel = EventMachine::Channel.new
        #   reader = Reader.new
        #   rp = Parser.new(channel, reader)
        #
        # @param channel [Channel]
        #   An EventMachine channel that should receive parsed responses.
        # @param reader [Reader]
        #   An object that converts raw buffered data to BAPS protocol tokens.
        def initialize(channel, reader)
          @channel = channel
          @reader = reader

          # Set up to expect the welcome message
          @expected = [%i(message string)]
          @response = OpenStruct.new(
            code: Codes::System::WELCOME_MESSAGE,
            subcode: 0
          )
        end

        # Starts this Parser
        #
        # @api      semipublic
        # @example  Starts a Parser
        #   rp.start
        #
        # @return [void]
        def start
          word
        end

        # Attempt to scrape a command word off the top of the buffer
        #
        # If successful, the parser then interprets the word and sets up to
        # parse the rest of the command phrase.
        #
        # @api private
        #
        # @return [void] Whether there was enough data to process a command
        def command
          # We could use the second return from reader.command to skip an
          # unknown message, but BAPS is quite dodgy at implementing this in
          # places, so we don't do it in practice.
          @reader.command do |code|
            parse_command(CommandWord.new(code))
            word
          end
        end

        # Parses a command word and sets up to parse the following arguments
        #
        # @api private
        #
        # @param raw_code [CommandWord] The raw code word from the BAPS server.
        #
        # @return [void]
        def parse_command(raw_code)
          code, subcode = raw_code.split
          @expected = structure_with_code(code)
          @response = response_with_code(code, subcode)
        end

        # Retrieves the expected set of arguments for the given BAPS command
        #
        # @api private
        #
        # @param code [Integer]
        #   The BAPS command code whose arguments are sought.
        #
        # @return [Array]
        #   The expected structure of the BAPS response.
        def structure_with_code(code)
          structure = Baps::Responses::Structures.structure(code)
          structure.nil? ? unknown_response(code) : structure.clone
        end

        # Fails if the response with the given code is not understood
        #
        # In order to understand the structure of the following bytes from the
        # BAPS server, every response received must be one for which the BAPS
        # service has a known expected format.  Thus, if an unknown response is
        # found, the service cannot continue and fails.
        #
        # @api private
        #
        # @param code [Integer]
        #   The BAPS command code of the unknown response.
        #
        # @return [void]
        def unknown_response(code)
          fail(Rapid::Common::Exceptions::InvalidPlayoutResponse, code.to_s(16))
        end

        # Constructs an initial response from the given code and subcode
        #
        # @api private
        #
        # @param code [Integer]
        #   The BAPS command code this response represents.
        # @param subcode [Integer]
        #   The sub-code of the BAPS command.
        #
        # @return [Hash]
        #   An initial response, ready for accepting argument fields.
        def response_with_code(code, subcode)
          OpenStruct.new(name: code_name(code), code: code, subcode: subcode)
        end

        # Finds a semi-human-readable name for a BAPS response code
        #
        # @api private
        #
        # @param code [Integer] The BAPS command code whose name is sought.
        #
        # @return [String] The code's name.
        def code_name(code)
          Codes.code_symbol(code)
        end

        # Attempt to grab an argument word from the reader
        #
        # If there are no arguments left, the parser is set back into command
        # reading mode and the completed response is sent to the dispatch.
        #
        # @api private
        #
        # @return [Boolean] Whether or not there was enough data to process a
        #   data word.
        def word
          @expected.empty? ? finish_response : continue_response
        end

        # Reads a config setting
        #
        # Config settings are one of the uglier areas of BAPS's meta-protocol,
        # as the format of the config value depends on the preceding config
        # type. As such, it's much easier to treat them specially in the
        # parser.
        #
        # This command only parses the setting type itself; it pushes the
        # correct type for the value into @expected as the next argument.
        #
        # @api private
        #
        # @param name [Symbol] The name of the argument to which the config
        #   type is bound.
        #
        # @return [void]
        def config_setting(name)
          @reader.uint32 do |config_type|
            @response[name] = config_type
            @reader.send(CONFIG_TYPE_MAP[config_type]) do |value|
              @response.value = value
              word
            end
          end
        end

        # Reads the body of a LOAD command
        #
        # LOAD commands change their format depending on the track type, so we
        # have to parse them specially.
        #
        # This command only parses the loaded item type itself; it pushes the
        # correct arguments for each item type into @expected as the arguments
        # immediately following this one.
        #
        # @api private
        #
        # @param name [Symbol]
        #   The name of the argument to which the track type is bound.
        #
        # @return [void]
        def load_body(name)
          @reader.uint32 do |track_type|
            add_arguments(track_type)
            @response[name] = track_type
            word
          end
        end

        # Adds the correct expected arguments for a load body
        #
        # @api private
        #
        # @param track_type [Fixnum]
        #   The 32-bit integer representing the track type.
        #
        # @return [void]
        def add_arguments(track_type)
          @expected.unshift(*LOAD_ARGUMENTS[track_type])
        end

        # Parses a word with a primitive type
        #
        # A primitive type is one which is implemented in BapsReader, and only
        # requires one buffer read.  Other types are implemented in terms of
        # special parser logic on these types, by the Parser itself.
        #
        # @api private
        #
        # @param parameter [Array] The argument's parameter name, its type
        #   symbol, and any other arguments to the primitive type function.
        #
        # @return [Object] The argument if it was successfully read, or nil
        #   otherwise.  An unsuccessful read implies that the read should be
        #   retried when the reader's buffer fills up.
        def primitive(parameter)
          name, arg_type, *args = parameter

          @reader.public_send(arg_type, *args) do |value|
            @response[name] = value
            word
          end
        end

        # Finishes a response and creates a clean slate for the next one
        #
        # @api private
        #
        # @return [Boolean] true (as in, this method always succeeds at
        #   processing data).
        def finish_response
          @channel.push(@response)
          @response = nil
          command
        end

        # Attempt to grab an argument word from the reader
        #
        # This function expects there to indeed be another argument word.
        # The caller should ensure this.
        #
        # @api private
        #
        # @return [void]
        def continue_response
          parameter = @expected.shift
          name, type, *args = parameter

          # Some command words can be read from the buffer directly, whereas
          # the parser has its own logic for the more complex ones.
          own_type = respond_to?(type, true)
          own_type ? send(type, name, *args) : primitive(parameter)
        end

        # A map of configuration types to their meta-protocol types.
        CONFIG_TYPE_MAP = {
          Types::Config::CHOICE => :uint32,
          Types::Config::INT    => :uint32,
          Types::Config::STR    => :string
        }

        DURATION      = %i(duration uint32)
        TEXT_CONTENTS = %i(contents string)
        TITLE         = %i(title string)

        LOAD_ARGUMENTS = {
          Types::Track::VOID    => [TITLE],
          Types::Track::FILE    => [TITLE, DURATION],
          Types::Track::LIBRARY => [TITLE, DURATION],
          Types::Track::TEXT    => [TITLE, TEXT_CONTENTS]
        }
      end
    end
  end
end
