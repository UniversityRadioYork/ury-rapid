module Bra
  module DriverCommon
    module Requests
      # Mixin for anything that needs to parse playlist references
      #
      # Playlist references refer to items in playlists inside the model's
      # playlist set, by their position indices and playlist IDs respectively.
      #
      # A playlist reference is either a local or foreign playlist reference:
      #
      # - Local references are the pseudo-URL body '<playlist-index>' or the
      #   hash { index: <playlist-index> }, and reference an index in the
      #   playlist whose ID is returned by #local_playlist_id;
      # - Foreign references are the pseudo-URL body
      #   '<playlist-id>/<playlist-index>' or the hash
      #   { playlist: <playlist-id>, index: <playlist-index>, and reference
      #   an index in the playlist with the specified ID.
      #
      # Implementors must implement the method #local_playlist_id to return
      # the ID of the 'current' playlist from the implementor's perspective,
      # or raise an error if there is no such playlist.
      module PlaylistReferenceParser
        # Given a playlist ID, determines whether it is the local playlist
        #
        # @api  public
        # @example  Passing the local playlist ID.
        #   p.local_playlist_id
        #   #=> :local_id
        #   p.local_playlist?(:local_id)
        #   #=> true
        # @example  Passing a foreign playlist ID.
        #   p.local_playlist_id
        #   #=> :local_id
        #   p.local_playlist?(:foreign_id)
        #   #=> false
        #
        # @param id [Symbol]  The playlist ID to check.
        #
        # @return [Boolean]  True if the playlist is local; false otherwise.
        def local_playlist?(id)
          id == local_playlist_id
        end

        # Parses a URL body as a playlist reference
        #
        # @api  public
        # @example  Parsing a local playlist reference.
        #   parser.local_playlist_id
        #   #=> :local_id
        #   parser.parse_playlist_reference_url('20')
        #   #=> [:local_id, 20]
        # @example  Parsing a foreign playlist reference.
        #   p.local_playlist_id
        #   #=> :local_id
        #   p.parse_playlist_reference_url('foreign_id/20')
        #   #=> [:foreign_id, 20]
        #
        # @param url [String]  The URL body to parse.  This should not have the
        #   protocol, as this should already have been dealt with.
        #
        # @return [Array]  A tuple containing the playlist ID and index
        #   referred to by this reference.

        # Parses a hash as a playlist reference
        #
        # @api  public
        # @example  Parsing a local playlist reference.
        #   p.local_playlist_id
        #   #=> :local_id
        #   p.parse_playlist_reference_hash({index: 20})
        #   #=> [:local_id, 20]
        # @example  Parsing a foreign playlist reference.
        #   p.local_playlist_id
        #   #=> :local_id
        #   p.parse_playlist_reference_hash({playlist: :foreign_id, index: 20})
        #   #=> [:foreign_id, 20]
        #
        # @param hash [Hash]  The hash to parse.
        #
        # @return [Array]  A tuple containing the playlist ID and index
        #   referred to by this reference.

      end
    end
  end
end
