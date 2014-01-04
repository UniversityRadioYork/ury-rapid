require 'bra/driver_common/requests/handler'

module Bra
  module Baps
    module Requests
      module Handlers
        # Handler for playlists
        class Playlist < Bra::DriverCommon::Requests::Handler
          def_targets :playlist
          use_payload_processor_for :post
          put_by_posting_to_parent

          # Requests a playlist be DELETEd via the BAPS server
          #
          # This resets the playlist.
          def delete(object, _)
            request(Request.new(Codes::Playlist::RESET, id))
          end

          URL_PROTOCOLS = Hash.new_with_default_block({
            x_baps_file: :file_from_url
          }) { |h, k| unknown_protocol(k) }
          HASH_PROTOCOLS = Hash.new_with_default_block({
            x_baps_file:   :file_from_hash,
            x_baps_direct: :direct
          }) { |h, k| unknown_protocol(k) }

          def url(protocol, url)
            method(URL_PROTOCOLS[protocol]).call(url)
          end

          def hash(type, item)
            method(HASH_PROTOCOLS[type]).call(item)
          end

          private

          def add_item_request(type)
            Request.new(Codes::Playlist::ADD_ITEM, caller_id).uint32(type)
          end

          def direct(item)
            request(
              add_item_request(Types::Track::SPECIFIC_ITEM)
              .uint32(item[:record_id].to_i, item[:track_id].to_i)
              .string(item[:title], item[:artist])
            )
          end

          def file_from_hash(hash)
            file(*(hash.values_at(:directory, :filename)))
          end

          def file_from_url(url)
            file(*(url.split('/', 2)))
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
