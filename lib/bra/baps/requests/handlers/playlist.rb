require 'bra/driver_common/requests/url_hash_handler'

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
            request(Request.new(Codes::Playlist::RESET, id))
          end

          url_type :x_baps_file do |url|
            file(*(url.split('/', 2)))
          end

          hash_type :x_baps_file do |hash|
            file(*(hash.values_at(:directory, :filename)))
          end

          hash_type :x_baps_direct do |hash|
            request(
              add_item_request(Types::Track::SPECIFIC_ITEM)
              .uint32(item[:record_id].to_i, item[:track_id].to_i)
              .string(item[:title], item[:artist])
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
