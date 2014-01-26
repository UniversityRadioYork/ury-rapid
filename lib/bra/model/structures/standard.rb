require 'bra/common/types'
require 'bra/model'

module Bra
  module Model
    module Structures
      # A baseline model structure
      #
      # This contains:
      #   - The info node, which exposes information about the bra system to
      #     clients
      #   - The main system log
      class Standard < Bra::Model::Creator
        include Bra::Common::Types::Validators

        # Create the model from the given configuration
        #
        # @return [Root]  The finished model.
        def create
          root do
            info :info
            log  :log
          end
        end

        # Builds the bra information model.
        def info(id)
          hash(id, :info) do
            constant :version, Bra::Common::Constants::VERSION, :version
            constant :channel_mode, channel_mode?, :channel_mode
          end
        end

        # Determines whether the model is in 'channel mode'
        #
        # Channel mode means that the players and playlists are linked in
        # channels; this means the set of player and playlist IDs are equal.
        #
        # Some user interfaces will only work when bra is in channel mode, so
        # this is provided to allow them to check.
        #
        # @return [Boolean] True if the model is in channel mode; false if not.
        def channel_mode?
          option(:players) == option(:playlists)
        end
      end
    end
  end
end
