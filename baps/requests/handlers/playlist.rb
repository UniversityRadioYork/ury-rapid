require_relative '../handler'

module Bra
  module Baps
    module Requests
      module Handlers
        # Handler for playlists
        #
        # This handler also targets channels and channel sets, because these
        # all have similar DELETE semantics.
        class Playlist < Handler
          # The handler targets matched by this handler.
          TARGETS = [:playlist, :channel, :channel_set]
          PROTOCOLS = Hash.new{ |h, k| unknown_protocol(h, k) }.merge!({
            'x-baps-libraryitem' => :libraryitem,
            'x-baps-file' => :file
          })

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
            # TODO(mattbw): Handle :channel and :channel_set properly
            fail('FIXME') unless object.handler_target == :playlist
            index, item = self.class.flatten_post(payload)

            channel_id = object.channel_id
            if item.is_a?(Hash)
              specificlibraryitem(channel_id, item)
            else
              self.class.handle_url(item) do |protocol, url|
                method(PROTOCOLS[protocol.downcase]).call(channel_id, url)
              end
            end

            false
          end

          private

          def unknown_protocol(protocol)
            fail("Unknown protocol: #{protocol}")
          end

          def libraryitem(channel_id, url)
            send(
              Request
              .new(Codes::Playlist::ADD_ITEM, channel_id)
              .uint32(Types::Track::LIBRARY)
              .uint32(url.to_i)
            )
          end

          def specificlibraryitem(channel_id, item)
            send(
              Request
              .new(Codes::Playlist::ADD_ITEM, channel_id)
              .uint32(Types::Track::SPECIFIC_ITEM)
              .uint32(item[:record_id].to_i)
              .uint32(item[:track_id].to_i)
              .string(item[:title])
              .string(item[:artist])
            )
          end


          def file(channel_id, url)
            directory, filename = url.split('/', 2)

            send(
              Request
              .new(Codes::Playlist::ADD_ITEM, channel_id)
              .uint32(Types::Track::FILE)
              .uint32(directory.to_i)
              .string(filename)
            )
          end

          # Resets a playlist given its channel ID.
          #
          # @api private
          #
          # @param id [Integer] The ID of the channel to reset.
          #
          # @return [void]
          def reset(id)
            send(Request.new(Codes::Playlist::RESET, id))
          end
        end
      end
    end
  end
end
