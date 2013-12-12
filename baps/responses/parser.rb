require 'active_support/core_ext/object/try'
require_relative '../codes'
require_relative '../types'

module Bra
  module Baps
    module Responses
      class UnknownResponse < StandardError
      end

      # An interpreter that reads and converts raw command data from the BAPS
      # server into response messages.
      class Parser
        # Initialises the parser
        #
        # @api semipublic
        #
        # @example Initialising a response parser.
        #   channel = EventMachine::Channel.new
        #   reader = Reader.new
        #   rp = Parser.new(channel, reader)
        #
        # @param channel [Channel] An EventMachine channel that should receive
        #   parsed responses.
        # @param reader [Reader] An object that can convert raw buffered data to
        #   BAPS meta-protocol tokens.
        def initialize(channel, reader)
          @channel = channel
          @reader = reader

          # Set up to expect the welcome message
          @expected = [%i(message string)]
          @response = {
            code: Codes::System::WELCOME_MESSAGE,
            subcode: 0
          }
        end

        # Read and interpret a response from the BAPS server
        #
        # @api semipublic
        #
        # @example Sending data to a Parser
        #   rp = Parser.new(channel, reader)
        #   rp.receive_data("data")
        #
        # @param data [String] Raw data from the server, as a byte-string.
        #
        # @return [void]
        def receive_data(data)
          @reader.add(data)

          sufficient_data = true
          sufficient_data = process_next_token while sufficient_data
        end

        private

        # Masks for splitting a BAPS command code into its main and sub-code
        MAIN_CODE_MASK = 0xFFF0
        SUBCODE_MASK   = 0x000F

        # Attempt to process the top of the buffer as part of a response
        #
        # @api private
        #
        # @return [Boolean] Whether there was enough data to process a command
        #   word or not.
        def process_next_token
          @response.nil? ? command : word
        end

        # Attempt to scrape a command word off the top of the buffer
        #
        # If successful, the parser then interprets the word and sets up to
        # parse the rest of the command phrase.
        #
        # @api private
        #
        # @return [Boolean] Whether there was enough data to process a command
        #   word or not.
        def command
          # We could use the second return from reader.command to skip an
          # unknown message, but BAPS is quite dodgy at implementing this in
          # places, so we don't do it in practice.
          command = @reader.command
          command.nil? ? false : parse_command(command.first)
        end

        # Parses a command word and sets up to parse the following arguments
        #
        # @api private
        #
        # @param raw_code [Integer] The raw code word from the BAPS server.
        #
        # @return [Boolean] Whether there was enough data to process a command
        #   word or not.
        def parse_command(raw_code)
          code, subcode = split_command_word(raw_code)
          @expected = structure_with_code(code)
          @response = response_with_code(code, subcode)

          true
        end

        # Splits a command word into its code and subcode.
        #
        # BAPS uses various bit-masks of its command word for various purposes.
        # The high bits generally encode the command type, while the low bits
        # encode the target channel, sub-commands, and other things.
        #
        # For our purposes, the subcode is the last four bits of the command
        # word.  This means that some subcommnds in BAPS are full commands in
        # the bra BAPS driver, but most of the commands where this happens
        # aren't supported by us anyway.
        #
        # @api private
        #
        # @param code [Integer] The raw BAPS command word to split.
        #
        # @return [Array] A pair of main command code and command sub-code.
        def split_command_word(code)
          [main_code(code), subcode(code)]
        end

        def main_code(code)
          code & MAIN_CODE_MASK
        end

        def subcode(code)
          code & SUBCODE_MASK
        end

        # Retrieves the expected set of arguments for the given BAPS command
        #
        # @api private
        #
        # @param code [Integer] The BAPS command code whose arguments are
        #  sought.
        #
        # @return [Array] The expected structure of the BAPS response.
        def structure_with_code(code)
          structure = Responses::STRUCTURES[code]
          structure.nil? ? unknown_response : structure.clone
        end

        def unknown_response(code)
          fail(UnknownResponse, code.to_s(16)) if structure.nil?
        end

        # Constructs an initial response from the given code and subcode
        #
        # @api private
        #
        # @param code [Integer] The BAPS command code this response represents.
        # @param subcode [Integer] The sub-code of the BAPS command.
        #
        # @return [Hash] An initial response, ready for adding fields to.
        def response_with_code(code, subcode)
          { name: code_name(code), code: code, subcode: subcode }
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

        # Reads a string argument
        #
        # This does not process the entire string in one go; this method reads
        # only the string length, and then pushes in a new argument for the
        # data itself.
        #
        # @api private
        #
        # @param name [Symbol] The name of the parameter whose argument is
        #   being read.
        #
        # @return [Boolean] Whether or not there was enough data to process a
        #   data word.
        def string(name)
          length = @reader.uint32
          @expected.unshift([name, :raw_bytes, length]) unless length.nil?

          !length.nil?
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
        # @return [Boolean] Whether or not there was enough data to process a
        #   data word.
        def config_setting(name)
          enough_data = false

          @reader.uint32.try do |config_type|
            @expected.unshift([:value, CONFIG_TYPE_MAP[config_type]])
            @response[name] = config_type
            enough_data = true
          end

          enough_data
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
        # @param name [Symbol] The name of the argument to which the track
        #   type is bound.
        #
        # @return [Boolean] Whether or not there was enough data to process a
        #   data word.
        def load_body(name)
          enough_data = false

          @reader.uint32.try do |track_type|
            # Note that these are in reverse order, as they're being shifted
            # onto the front.
            case track_type
            when Types::Track::VOID
              # No extra argument here.
            when Types::Track::TEXT
              @expected.unshift(TEXT_CONTENTS)
            else
              @expected.unshift(DURATION)
            end
            @expected.unshift(TITLE)

            @response[name] = track_type

            enough_data = true
          end

          enough_data
        end

        private

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

          data = @reader.public_send(arg_type, *args)
          @response[name] = data unless data.nil?

          !data.nil?
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
          true
        end

        # Attempt to grab an argument word from the reader
        #
        # This function expects there to indeed be another argument word.
        # The caller should ensure this.
        #
        # @api private
        #
        # @return [Boolean] Whether or not there was enough data to process a
        #   data word.
        def continue_response
          parameter = @expected.shift
          name, type, *args = parameter

          # Some command words can be read from the buffer directly, whereas
          # the parser has its own logic for the more complex ones.
          own_type = respond_to?(type, true)
          success = own_type ? send(type, name, *args) : primitive(parameter)

          @expected.unshift(parameter) unless success
          success
        end

        # A map of configuration types to their meta-protocol types.
        # functions for reading them.
        CONFIG_TYPE_MAP = {
          Types::Config::CHOICE => :uint32,
          Types::Config::INT => :uint32,
          Types::Config::STR => :string
        }

        DURATION = %i(duration uint32)
        TEXT_CONTENTS = %i(contents string)
        TITLE = %i(title string)
      end
    end
  end
end
