require 'ury_rapid/service_common/requests/handler_bundle'

module Rapid
  module Baps
    module Requests
      # Module for BAPS request handlers
      module Handlers
        extend Rapid::ServiceCommon::Requests::HandlerBundle

        playlist_handler 'Playlist', :playlist do
          on_delete { request Codes::Playlist::RESET, playlist_id }

          #
          # BAPS extensions to the Playlist API (see
          # Rapid::ServiceCommon::Requests::PlaylistHandler for the main API)
          #

          # x_baps_file
          #   URL: 'x_baps_file://directory/filename'
          #   Hash: {type: :x_baps_file, directory: dir, filename: filename}
          #
          #   Loads a file from one of BAPS's pre-configured directories.
          url_and_hash_type(
            :x_baps_file,
            ->(url) { url.split('/', 2) },
            ->(hash) { hash.values_at(:directory, :filename) }
          ) do |directory, filename|
            add_item_request(:file) do |rq|
              rq.uint32(directory.to_i).string(filename)
            end
          end

          # x_baps_direct
          #   Hash: {type:      :x_baps_direct,
          #          record_id: id,
          #          track_id:  id,
          #          title:     title,
          #          artist:    artist,
          #         }
          #
          #   Loads a track from the BAPS Record Library, with the given IDs
          #   and metadata.
          hash_type :x_baps_direct do |item|
            direct(*item.values_at(*%i(record_id track_id title artist)))
          end

          #
          # Implementations for the Playlist API
          #

          def text(summary, details)
            add_item_request(:text) { string(summary, details) }
          end

          # Moves an item inside the playlist being handled by this handler
          #
          # This is an implementation of the playlist API type 'move'.
          # BAPS does not support foreign playlist moves; use 'copy' instead.
          #
          # The destination index is the ID from the POST payload.
          #
          # @api semipublic
          # @example  Move from index 5 to the handled playlist.
          #   handler.move_from_local_playlist(5)
          #
          # @param old_index [Integer]  The source playlist index, starting
          #   from 0.
          #
          # @return [void]
          def move_from_local_playlist(old_index)
            new_index = payload_id
            request Codes::Playlist::MOVE_ITEM_IN_PLAYLIST, caller_id do
              uint32 old_index, new_index
            end
          end

          # Copies an item from another playlist to the one being handled
          #
          # This is an implementation of the playlist API type 'copy'.
          # BAPS does not support foreign playlist moves; use 'move' instead.
          #
          # The target ID is ignored by this call, because BAPS does not
          # support it.
          #
          # @api semipublic
          # @example  Copy from index 5 on playlist 0 to the handled playlist.
          #   handler.copy_from_foreign_playlist(0, 5)
          #
          # @param old_playlist [Integer]  The source playlist ID.  BAPS only
          #   supports integral playlist IDs.
          # @param old_index [Integer]  The source playlist index, starting
          #   from 0.
          #
          # @return [void]
          def copy_from_foreign_playlist(old_playlist, old_index)
            new_playlist = caller_id
            request Codes::Playlist::COPY_ITEM_TO_PLAYLIST, old_playlist do
              uint32 old_index, new_playlist
            end
          end

          private

          def add_item_request(type_symbol, &block)
            type = Types::Track.const_get(type_symbol.upcase)
            request Codes::Playlist::ADD_ITEM, caller_id do
              uint32 type
              instance_exec(&block)
            end
          end

          def direct(record_id, track_id, title, artist)
            add_item_request(:specific_item) do
              uint32 Integer(record_id), Integer(track_id)
              string title, artist
            end
          end
        end

        handler 'PlaylistSet', :playlist_set do
          delete_by_deleting_children
        end

        handler 'Item', :item do
          on_delete do
            unsupported_by_service unless in_playlist?

            request Codes::Playlist::DELETE_ITEM, caller_parent_id do
              uint32 caller_id
            end
          end

          private

          # Checks to see if the Item is in a playlist
          #
          # @api  private
          #
          # @return [Boolean]  True if the item is in a playlist; false
          #   otherwise.
          def in_playlist?
            caller_parent.handler_target == :playlist
          end
        end
      end
    end
  end
end
