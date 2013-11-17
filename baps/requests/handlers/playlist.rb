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

          private

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
