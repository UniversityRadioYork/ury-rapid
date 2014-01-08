require 'bra/common/types'
require 'bra/model'

# A normal model structure
#
# This contains:
#   - A player set, with IDs set in the model config under 'players'
#   - A playlist set, with IDs set in the model config under 'playlists'
class Structure < Bra::Model::Creator
  include Bra::Common::Types::Validators

  # Create the model from the given configuration
  #
  # @return [Root]  The finished model.
  def create
    root do
      hashes    :players, :player_set, option(:players), :player do
        player
      end
      lists     :playlists, :playlist_set, option(:playlists), :playlist
      info      :info
      log       :log
    end
  end

  # Creates a player
  #
  # In the standard structure, a player contains:
  #
  # - A variable holding the play state (playing/paused/stopped);
  # - A variable holding the load state (ok/loading/failed/empty);
  # - A variable for each position marker.
  def player
    component :state,      :play_state, :stopped
    component :load_state, :load_state, :empty
    component :volume,     :volume,     0.0
    Bra::Common::Types::MARKERS.each { |id| component id, :marker, id, 0 }
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
