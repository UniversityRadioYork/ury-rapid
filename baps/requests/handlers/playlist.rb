require_relative '../handler'

module Bra
  module Baps
    module Requests
      module Handlers
        # Handler for playlist
        class Playlist < Handler
          # The handler target matched by this handler.
          TARGET = :playlist

          # Requests a playlist be DELETEd via the BAPS server
          # 
          # This resets the playlist.
          def delete(object)
            send(Request.new(Codes::Playlist::RESET, object.channel_id))

            false
          end

          # TODO(mattbw): PUT
        end
      end
    end
  end
end
