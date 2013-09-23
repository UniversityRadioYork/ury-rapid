require 'active_support/core_ext/object/try'
require_relative 'codes'
require_relative 'types'

module Bra
  module Baps
    class UnknownResponse < StandardError
    end

    # Internal: An interpreter that reads and converts raw command data from
    # the BAPS server into response messages.
    class ResponseParser
      # Internal: Initialises the parser.
      #
      # dispatch - The target of completed responses.
      # reader   - An object that can convert raw buffered data to BAPS
      #            meta-protocol tokens.
      def initialize(dispatch, reader)
        @dispatch = dispatch
        @reader = reader

        # Set up to expect the welcome message
        @expected = [%i(message string)]
        @response = {
          name: 'WelcomeMessage',
          code: Codes::System::WELCOME_MESSAGE,
          subcode: 0
        }
      end

      # Internal: Read and interpret a response from the BAPS server.
      def receive_data(data)
        @reader.add data

        sufficient_data = true
        sufficient_data = process_next_token while sufficient_data
      end

      # Internal: Attempt to process the top of the buffer as part of a
      # response.
      def process_next_token
        @response.nil? ? command : word
      end

      # Internal: Attempt to scrape a command word off the top of the buffer.
      # If successful, the parser then interprets the word and sets up to
      # parse the rest of the command phrase.
      #
      # Returns a boolean specifying whether there was enough data to process
      #   a command word or not.
      def command
        enough_data = false
        # We could use the second return from reader.command to skip an
        # unknown message, but BAPS is quite dodgy at implementing this in
        # places, so we don't do it in practice.
        @reader.command.try(:first).try do |raw_code|
          code, subcode = (raw_code & 0xFFF0), (raw_code & 0x000F)
          @expected, @response = command_with_code(code, subcode)
          enough_data = true
        end

        enough_data
      end

      # Internal: Parses and initialises a command whose BAPS code and subcode
      # are given.
      #
      # code    - The response's BAPS command code (a 16-bit integer).
      # subcode - The subcode (for example, the affected channel number).
      #
      # Returns (as a list) the new response and expected arguments list, which
      # should generally go to @response and @expected respectively.
      def command_with_code(code, subcode)
        responses = Responses::STRUCTURES
        fail(UnknownResponse, code.to_s(16)) unless responses.key?(code)

        name, *expected = responses[code]
        response = { name: name, code: code, subcode: subcode }

        [expected, response]
      end

      # Internal: Attempt to grab an argument word from the reader.
      # If there are no arguments left, the parser is set back into command
      # reading mode and the completed response is sent to the dispatch.
      #
      # Returns a boolean specifying whether there was enough data to process
      #   a data word or not.
      def word
        @expected.empty? ? finish_response : continue_response
      end

      # Internal: Reads a string argument.
      #
      # This does not process the entire string in one go; this method reads
      # only the string length, and then pushes in a new argument for the
      # data itself.
      #
      # name - The name of the parameter whose argument is being read.
      #
      # Returns a boolean specifying whether there was enough data to process
      #   the string length or not.
      def string(name)
        length = @reader.uint32
        @expected.unshift([name, :raw_bytes, length]) unless length.nil?

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
        enough_data = false

        @reader.uint32.try do |config_type|
          @expected.unshift([:value, CONFIG_TYPE_MAP[config_type]])
          @response[name] = config_type
          enough_data = true
        end

        enough_data
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
        enough_data = false

        @reader.uint32.try do |track_type|
          # Note that these are in reverse order, as they're being shifted
          # onto the front.
          @expected.unshift(DURATION) unless track_type == Types::Track::NULL
          @expected.unshift(TITLE)

          @response[name] = track_type

          enough_data = true
        end

        enough_data
      end

      private

      # Internal: Parses a word with a primitive type.
      #
      # A primitive type is one which is implemented in BapsReader, and only
      # requires one buffer read.  Other types are implemented in terms of
      # special parser logic on these types, by the Parser itself.
      #
      # word_description - A list containing the argument's parameter name,
      #                    its type symbol, and any other arguments to the
      #                    primitive type function.
      #
      # Returns the argument if it was successfully read, or nil otherwise.
      #   An unsuccessful read implies that the read should be retried when the
      #   reader's buffer fills up.
      def primitive_word(word_description)
        name, arg_type, *args = word_description

        data = @reader.public_send(arg_type, *args)
        @response[name] = data unless data.nil?

        !data.nil?
      end

      # Internal: Finishes the current response and creates a clean slate for
      # the next one to begin.
      #
      # Returns true (as in, this method always succeeds at processing data).
      def finish_response
        @dispatch.emit(@response)
        @response = nil
        true
      end

      # Internal: Attempt to grab an argument word from the reader.
      #
      # This function expects there to indeed be another argument word.
      # The caller should ensure this.
      #
      # Returns a boolean specifying whether there was enough data to process
      # a data word or not.
      def continue_response
        word_description = @expected.shift
        name, arg_type, *args = word_description

        # Some command words can be read from the buffer directly, whereas
        # the parser has its own logic for the more complex ones.
        success = send(arg_type, name, *args) if respond_to? arg_type
        success = primitive_word(word_description) unless respond_to? arg_type

        @expected.unshift(word_description) unless success
        success
      end

      # Internal: A map of configuration types to their meta-protocol types.
      # functions for reading them.
      CONFIG_TYPE_MAP = {
        Types::Config::CHOICE => :uint32,
        Types::Config::INT => :uint32,
        Types::Config::STR => :string
      }

      DURATION = %i(duration uint32)
      TITLE = %i(title string)
    end
  end
end
