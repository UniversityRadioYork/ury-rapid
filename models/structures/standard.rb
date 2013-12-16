require_relative '../creator'
require_relative '../model'
require_relative '../playlist'
require_relative '../player'
require_relative '../variable'
require_relative '../info'
require_relative '../../common/types'


# A normal model structure
#
# This contains:
#   - A player set, with IDs set in the model config under 'players'
#   - A playlist set, with IDs set in the model config under 'playlists'
class Structure < Bra::Models::Creator
  include Bra::Common::Types::Validators

  # Create the model from the given configuration
  #
  # @return [Root]  The finished model.
  def create
    root Bra::Models::Root do
      set(:players, Bra::Models::Player, option(:players)) { player }
      set(:playlists, Bra::Models::Playlist, option(:playlists))
      info :info
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
    child :state,      var(:player_state,      play_validator, :stopped)
    child :load_state, var(:player_load_state, load_validator, :empty)
    Bra::Common::Types::MARKERS.each do |id|
      child id, var("player_#{id}".intern, marker_validator, 0)
    end
  end

  def play_validator
    method(:validate_play_state)
  end

  def load_validator
    method(:validate_load_state)
  end

  # Validates an incoming marker
  def marker_validator
    proc do |position|
      position ||= 0
      position_int = Integer(position)
      fail('Position is negative.') if position_int < 0
      # TODO: Check against duration?
      position_int
    end
  end

  # Builds the bra information model.
  def info(id)
    child(id, Bra::Models::Info) do
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
