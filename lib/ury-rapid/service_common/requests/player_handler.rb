require 'ury-rapid/service_common/requests/handler'
require 'ury-rapid/service_common/requests/url_hash_handler'
require 'ury-rapid/service_common/requests/playlist_reference_parser'

module Rapid
  module ServiceCommon
    module Requests
      # Base class for handlers that handle requests on players
      #
      # This provides boilerplate code for working with the standard Rapid
      # player API.
      class PlayerHandler < UrlHashHandler
        # The items POSTed to the player may be playlist references, so we
        # need to include the parser for them.
        include PlaylistReferenceParser
        alias_method :local_playlist_id, :caller_id

        # The caller of a player handler is the player
        alias_method :player_id, :caller_id

        # The only objects this handler takes responsibility for POSTing to the
        # playout server are items, which always come in on ID :item.
        # Every other POST goes to the ID'd child as a PUT.
        use_payload_processor_for :post, :item
        post_by_putting_to_child_for :volume, :state, :load_state
        post_by_putting_to_child_for :position, :cue, :intro

        # In the current version of the Rapid API, the standard methods for
        # POSTING an item into a player are:

        # playlist
        #   URL: 'playlist://[src-playlist/]src-index
        #   Hash: {type: :playlist, [playlist: src-playlist,] index: src-index}
        #
        #   Loads an item that is already at the given playlist reference.
        #
        #   If no source playlist is given, the playlist with the same ID as
        #   this player is substituted.  This can be useful in playout systems
        #   with linked players and playlists.
        #
        #   Services MAY choose not to implement this command.
        #
        #   Services may implement this by overriding #item_from_local_playlist
        #   and #item_from_foreign_playlist.
        playlist_reference_type :playlist do |playlist, index|
          local = local_playlist?(playlist)
          item_from_local_playlist(index)                 if local
          item_from_foreign_playlist(playlist, index) unless local
        end
        service_should_override :item_from_local_playlist
        service_should_override :item_from_foreign_playlist
      end
    end
  end
end
