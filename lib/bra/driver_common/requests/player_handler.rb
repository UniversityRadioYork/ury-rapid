require 'bra/driver_common/requests/handler'
require 'bra/driver_common/requests/url_hash_handler'
require 'bra/driver_common/requests/playlist_reference_parser'

module Bra
  module DriverCommon
    module Requests
      # Base class for handlers that handle requests on playyers
      #
      # This provides boilerplate code for working with the standard bra player
      # API.
      class PlayerHandler < UrlHashHandler
        include PlaylistReferenceParser
        alias_method :caller_id, :local_playlist_id

        # The only objects this handler takes responsibility for POSTing to the
        # playout server are items, which always come in on ID :item.
        # Every other POST goes to the ID'd child as a PUT.
        use_payload_processor_for :post, :item
        post_by_putting_to_child_for :volume, :state, :load_state
        post_by_putting_to_child_for :position, :cue, :intro

        # In the current version of the bra API, the standard methods for
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
        #   Drivers MAY choose not to implement this command.
        #
        #   Drivers may implement this by overriding #item_from_local_playlist
        #   and #item_from_foreign_playlist.
        # Supported URL protocols in this version of the bra API.
        url_type :playlist do |url|
          item_from_playlist(*parse_playlist_reference_url(url))
        end
        hash_type :playlist do |hash|
          item_from_playlist(*parse_playlist_reference_hash(hash))
        end

        # These are the overridable functions a concrete PlayerHandler can fill
        # in.  They are defined in this class as raising a NotSupportedByDriver
        # exception.
        TO_OVERRIDE = [
          :item_from_local_playlist,  # index
          :item_from_foreign_playlist # playlist_id, index
        ]
        TO_OVERRIDE.each do |method_symbol|
          define_method(method_symbol) do |*args|
            fail(Bra::Common::Exceptions::NotSupportedByDriver)
          end
        end

        protected

        def item_from_playlist(playlist, index)
          local = local_playlist?(playlist)
          item_from_local_playlist(index)                 if local
          item_from_foreign_playlist(playlist, index) unless local
        end
      end
    end
  end
end
