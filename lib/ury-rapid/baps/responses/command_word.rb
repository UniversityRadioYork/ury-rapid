module Rapid
  module Baps
    module Responses
      # An object representing a BAPS command word
      #
      # BAPS command words may be split into two separate codes:
      #
      # * A _code_, which identifies the general BAPS command itself;
      # * A _sub-code_, which identifies variants of BAPS commands.
      #
      # The CommandWord class contains a method, #split, for splitting the word
      # into these two codes.
      class CommandWord
        # Initialises a CommandWord
        #
        # @api      public
        # @example  Creating a new CommandWord
        #   word = CommandWord.new(0x330)
        #
        # @param raw [Integer]
        #   The raw 16-bit integer representing the command word as read from a
        #   BAPS server.
        def initialize(raw)
          @raw = raw
        end

        # Splits this command word into its code and subcode
        #
        # BAPS uses various bit-masks of its command word for various purposes.
        # The high bits generally encode the command type, while the low bits
        # encode the target channel, sub-commands, and other things.
        #
        # For our purposes, the subcode is the last four bits of the command
        # word.  This means that some subcommands in BAPS are full commands in
        # the Rapid BAPS service, but most of the commands where this happens
        # aren't supported by us anyway.
        #
        # @api      public
        # @example  Split a command word.
        #   cw = CommandWord.new(0x330)
        #   cw.split
        #   #=> [0x300, 0x30]
        #
        # @return [Array]
        #   A pair of main command code and command sub-code.
        def split
          [main_code, sub_code]
        end

        # Extracts the BAPS command code from this command word
        #
        # @api      public
        # @example  Retrieve the command code from a command word.
        #   cw = CommandWord.new(0x330)
        #   cw.main_code
        #   #=> [0x300]
        #
        # @return [Integer]
        #   The command code of this command word.
        def main_code
          @raw & MAIN_CODE_MASK
        end

        # Extracts the BAPS command sub-code from a command word
        #
        # @api      public
        # @example  Retrieve the command sub-code from a command word.
        #   cw = CommandWord.new(0x330)
        #   cw.sub_code
        #   #=> [0x30]
        #
        # @return [Integer]
        #   The sub-code of this command word.
        def sub_code
          @raw & SUBCODE_MASK
        end

        private

        # Masks for splitting a BAPS command code into its main and sub-code
        MAIN_CODE_MASK = 0xFFF0
        SUBCODE_MASK   = 0x000F
      end
    end
  end
end
