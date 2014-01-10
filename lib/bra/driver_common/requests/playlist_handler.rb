require 'bra/driver_common/requests/url_hash_handler'

module Bra
  module DriverCommon
    module Requests
      # Base class for handlers that handle requests on playlists
      #
      # This provides boilerplate code for working with the standard bra
      # playlist API.
      class PlaylistHandler < UrlHashHandler
        # The items POSTed to the playlist may be playlist references, so we
        # need to include the parser for them.
        include PlaylistReferenceParser
        alias_method :local_playlist_id, :caller_id

        # All objects POSTed to the playlist will be items, so we process their
        # payloads to find out what sort of item load they represent.
        use_payload_processor_for :post

        # In the current version of the bra API, the standard methods for
        # POSTing an item into a playlist are:

        # move
        #   URL: 'move://[old-playlist/]old-index
        #   Hash: {type: :move, [playlist: old-playlist,] index: old-index}
        #
        #   Moves the item from the given playlist reference to the playlist
        #   and index it is being POSTed to.
        #
        #   Drivers MAY choose not to implement non-local playlist moves, but
        #   SHOULD implement some form of move.
        #
        #   Drivers may implement this by overriding #move_local and
        #   #move_foreign.
        url_type(:move)  { |url|  move(*parse_playlist_reference_url(url)) }
        hash_type(:move) { |hash| move(*parse_playlist_reference_hash(hash)) }

        # text
        #   Hash: {type: :text, summary: 'summary', details: 'string'}
        #
        #   Adds a text item into the playlist, if the playout system supports
        #   text items.
        #
        #   Drivers may implement this by overriding #text.
        hash_type(:text) { |hash| text(hash[:summary], hash[:details]) }

        # These are the overridable functions a concrete PlaylistHandler can
        # fill in.  They are defined in this class as raising a
        # NotSupportedByDriver exception.
        TO_OVERRIDE = [
          :move_from_local_playlist,  # index
          :move_from_foreign_playlist # playlist_id, index
        ]
        TO_OVERRIDE.each do |method_symbol|
          define_method(method_symbol) do |*args|
            fail(Bra::Common::Exceptions::NotSupportedByDriver)
          end
        end

        protected

        def move(playlist, index)
          local = local_playlist?(playlist)
          move_from_local_playlist(index)                 if local
          move_from_foreign_playlist(playlist, index) unless local
        end
      end
    end
  end
end

