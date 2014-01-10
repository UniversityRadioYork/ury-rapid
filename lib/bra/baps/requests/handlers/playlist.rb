require 'bra/driver_common/requests/handler'
require 'bra/driver_common/requests/playlist_handler'

module Bra
  module Baps
    module Requests
      module Handlers
        extend Bra::DriverCommon::Requests::HandlerBundle

        # Handler for playlists
        class Playlist < Bra::DriverCommon::Requests::PlaylistHandler
          def_targets :playlist

          # Requests a playlist be DELETEd via the BAPS server
          #
          # This resets the playlist.
          def delete(object, _)
            request(Request.new(Codes::Playlist::RESET, caller_id))
          end

          # Methods of adding files that are specific to BAPS.

          url_type(:x_baps_file) { |url| file(*(url.split('/', 2))) }
          hash_type :x_baps_file do |hash|
            file(*(hash.values_at(:directory, :filename)))
          end

          # Direct library loading
          hash_type :x_baps_direct do |item|
            direct(*item.values_at(*%i{record_id track_id title artist}))
          end

          #
          # Implementations of PlaylistHandler load types
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
          def delete(object, payload)
            object.children.each { |child| child.delete(payload) }
          end
        end

        handler 'Item', :item do
          # Deletes the Item
          #
          # This only works if the Item is attached to a playlist.
          def delete
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
