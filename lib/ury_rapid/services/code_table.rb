module Rapid
  module Services
    # Helper module for modules representing playout system command codes
    module CodeTable
      # Given a code, return a vaguely descriptive textual description
      #
      # This is mainly intended for debugging and logging purposes, and is
      # wholly inadequate for user-facing code.  You have been warned!
      #
      # @api semipublic
      #
      # @example Find the name of a command code.
      #   # Assuming Rapid::Baps::Codes includes CodeTable,
      #   Rapid::Baps::Codes.code_symbol(Rapid::Baps::Codes::Playback::PLAY)
      #   #=> "Rapid::Baps::Codes::Playback::PLAY"
      #
      # @param code [Integer] A code in the code table.
      #
      # @return [String] The (semi) human-readable name for the code.
      def code_symbol(code)
        # Assume that the only constants defined in Codes are code groups...
        submodules = constants.map(&method(:const_get))
        # ...and the only constants defined in code groups are codes, and they
        # are disjoint.
        found = nil
        submodules.each { |s| found = find_code_in(s, code) unless found }
        fail("Unknown code number: #{code.to_s(16)}") unless found
        found
      end

      private

      # Attempts to find the name of a command code in a submodule
      #
      # @api private
      #
      # @param submodule [Module]
      #   The submodule to search for the code's name.
      # @param code [Integer]
      #   One of the codes from Rapid::Baps::Codes.
      #
      # @return [String]
      #   The (semi) human-readable name for the command code.
      #
      def find_code_in(submodule, code)
        submodule.constants
          .find { |name| submodule.const_get(name) == code }
          .try  { |name| "#{submodule}::#{name}" }
      end
    end
  end
end
