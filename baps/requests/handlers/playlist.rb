require_relative '../../../driver_common/requests/handler'
require_relative '../../../driver_common/requests/poster'

module Bra
  module Baps
    module Requests
      module Handlers
        # Handler for playlists
        #
        # This handler also targets channels and channel sets, because these
        # all have similar DELETE semantics.
        class Playlist < Bra::DriverCommon::Requests::Handler
          # The handler targets matched by this handler.
          TARGETS = [:playlist, :channel, :channel_set]

          # Requests a playlist be DELETEd via the BAPS server
          #
          # This resets the playlist.
          def delete(object)
            case object.handler_target
            when :playlist
              reset(object.channel_id)
            when :channel
              reset(object.id)
            when :channel_set
              object.children.map(&:id).each(&method(:reset))
            end

            false
          end

          # TODO(mattbw): PUT

          def post(object, payload)
            fail('FIXME') unless object.handler_target == :playlist
            PlaylistPoster.post(payload, self, object)
          end

          # Resets a playlist given its channel ID.
          #
          # @api private
          #
          # @param id [Integer] The ID of the channel to reset.
          #
          # @return [void]
          def reset(id)
            request(Request.new(Codes::Playlist::RESET, id))
          end
        end

        # Object that performs the POSTing of a playlist item.
        class PlaylistPoster < Bra::DriverCommon::Requests::Poster
          URL_PROTOCOLS = Hash.new_with_default_block({
            x_baps_file: :file_from_url
          }) { |h, k| unknown_protocol(k) }
          HASH_PROTOCOLS = Hash.new_with_default_block({
            x_baps_file:   :file_from_hash,
            x_baps_direct: :direct
          }) { |h, k| unknown_protocol(k) }

          def post_url(protocol, url)
            method(URL_PROTOCOLS[protocol]).call(url)
          end

          def post_hash(type, item)
            method(HASH_PROTOCOLS[type]).call(item)
          end

          # Given a payload, decides whether to forward it elsewhere
          #
          # @return [Boolean] false.
          def post_forward
            false
          end

          private

          def channel_id
            @object.channel_id
          end

          def add_item_request(type)
            Request.new(Codes::Playlist::ADD_ITEM, channel_id).uint32(type)
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
      end
    end
  end
end
