require_relative 'channel'
require_relative 'model_object'
require_relative 'player'
require_relative 'item'

module Bra
  module Models
    # Public: A model of the BAPS server state.
    class Root < HashModelObject
      extend Forwardable

      def channels
        child(:channels)
      end

      # Public: Access one of the playback channels.
      #
      # number - The number of the channel (0-(num_channels - 1)).
      #
      # Returns the Channel object.
      def channel(number)
        channels.channel(Integer(number))
      end

      def_delegator :channels, :player
      def_delegator :channels, :playlist
      def_delegator :channels, :player_state
      def_delegator :channels, :player_load_state
      def_delegator :channels, :player_marker

      # Public: Change the current item and load state for a channel player.
      #
      # number    - The number of the channel (0 onwards).
      # new_state - The symbol (must be one of :ok, :loading or :failed)
      #             representing the new state.
      # new_item  - The Item representing the new loaded item.
      def load_in_player(number, new_state, new_item)
        channels.load_in_player(number, new_state, new_item)
      end

      # Public: Return the item at the given index of the playlist for the
      # channel with the given ID.
      #
      # number    - The number of the channel (0 onwards).
      # index     - The index into the playlist, also as an integer starting
      #             from 0 or any Integer-coercible type.
      #
      # Returns an array representing the playlist data
      def playlist_item(number, index)
        channels.playlist_item(number, index)
      end

      # Public: Returns the canonical URL of the model channel list.
      #
      # Returns the URL, relative to the API root.
      def url
        id
      end

      def parent_url
        fail('Tried to get parent URL of the model root.')
      end

      def id
        ''
      end
    end
  end
end
