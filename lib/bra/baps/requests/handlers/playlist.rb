require 'bra/driver_common/requests/playlist_handler'

module Bra
  module Baps
    module Requests
      module Handlers
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
          hash_type :x_baps_direct do |hash|
            request(
              add_item_request(Types::Track::SPECIFIC_ITEM)
              .uint32(item[:record_id].to_i, item[:track_id].to_i)
              .string(item[:title], item[:artist])
            )
          end

          def move_from_local_playlist(new_index)
            request(
              Request.new(Codes::Playlist::MOVE_ITEM_IN_PLAYLIST, caller_id)
              .uint32(payload_id, new_index)
            )
          end

          private

          def add_item_request(type)
            Request.new(Codes::Playlist::ADD_ITEM, caller_id).uint32(type)
          end

          def file(directory, filename)
            request(
              add_item_request(Types::Track::FILE)
              .uint32(directory.to_i)
              .string(filename)
            )
          end
        end

        # Handler for playlist sets
        class PlaylistSet < Bra::DriverCommon::Requests::Handler
          def_targets :playlist_set

          def delete(object, payload)
            object.children.each { |child| child.delete(payload) }
          end
        end
      end
    end
  end
end
