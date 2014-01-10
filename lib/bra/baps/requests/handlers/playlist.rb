require 'bra/driver_common/requests/handler_bundle'

module Bra
  module Baps
    module Requests
      module Handlers
        extend Bra::DriverCommon::Requests::HandlerBundle

        playlist_handler 'Playlist', :playlist do
          on_delete do
            request(Request.new(Codes::Playlist::RESET, playlist_id))
          end

          #
          # BAPS extensions to the Playlist API
          # (see Bra::DriverCommon::Requests::PlaylistHandler for the main API)
          # 

          # x_baps_file
          #   URL: 'x_baps_file://directory/filename'
          #   Hash: {type: :x_baps_file, directory: dir, filename: filename}
          #
          #   Loads a file from one of BAPS's pre-configured directories.
          url_type(:x_baps_file) { |url| file(*(url.split('/', 2))) }
          hash_type :x_baps_file do |hash|
            file(*(hash.values_at(:directory, :filename)))
          end

          # x_baps_direct
          #   Hash: {type:      :x_baps_direct,
          #          record_id: id,
          #          track_id:  id,
          #          title:     title,
          #          artist:    artis,
          #         }
          #
          #   Loads a track from the BAPS Record Library, with the given IDs
          #   and metadata.
          hash_type :x_baps_direct do |item|
            direct(*item.values_at(*%i{record_id track_id title artist}))
          end

          #
          # Implementations for the Playlist API
          #

          def text(summary, details)
            add_item_request(:text) { |rq| rq.string(summary, details) }
          end

          def move_from_local_playlist(old_index)
            request(
              Request.new(Codes::Playlist::MOVE_ITEM_IN_PLAYLIST, caller_id)
              .uint32(old_index, payload_id)
            )
          end

          private

          def add_item_request(type_symbol)
            type = Types::Track::const_get(type_symbol.upcase)
            rq = Request.new(Codes::Playlist::ADD_ITEM, caller_id).uint32(type)
            request(yield rq)
          end

          def direct(record_id, track_id, title, artist)
            add_item_request(:specific_item) do |rq|
              rq.uint32(Integer(record_id), Integer(track_id))
                .string(title, artist)
            end
          end

          def file(directory, filename)
            add_item_request(:file) do |rq|
              rq.uint32(directory.to_i).string(filename)
            end
          end
        end

        handler 'PlaylistSet', :playlist_set do
          on_delete do
            object.children.each { |child| child.delete(payload) }
          end
        end

        handler 'Item', :item do
          on_delete do
            unsupported_by_driver unless in_playlist?

            request(
              Request.new(Codes::Playlist::DELETE_ITEM, caller_parent_id)
                     .uint32(caller_id)
            )
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
