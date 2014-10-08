require 'ury_rapid/baps/responses/handlers/handler'
require 'ury_rapid/baps/responses/handlers/loader'

module Rapid
  module Baps
    module Responses
      module Handlers
        # Base class for BAPS2 playback response handlers
        class PlayerHandler < Handler
          def run
            do_insert unless ignore_response?
          end

          protected

          def ignore_response?
            false
          end

          def do_insert
            insert(player_url, id, body)
          end
        end

        # Handler for BAPS2 channel state changes
        class State < PlayerHandler
          def_targets(
            Codes::Playback::PLAY,
            Codes::Playback::PAUSE,
            Codes::Playback::STOP
          )

          CODES_TO_STATES = {
            Codes::Playback::PLAY  => :playing,
            Codes::Playback::PAUSE => :paused,
            Codes::Playback::STOP  => :stopped
          }

          private

          def id
            :state
          end

          def ignore_response?
            find(player_url(id)).value == state
          end

          def body
            create_model_object(:play_state, state)
          end

          def state
            CODES_TO_STATES[@response.code]
          end
        end

        # Handler for BAPS2 channel volume changes
        class Volume < PlayerHandler
          def_targets Codes::Playback::VOLUME

          private

          def id
            :volume
          end

          def ignore_response?
            find(player_url(id)).value == @response.volume
          end

          def body
            create_model_object(:volume, @response.volume)
          end
        end

        # Handler for BAPS2 channel marker changes
        class Marker < PlayerHandler
          def_targets(
            Codes::Playback::POSITION,
            Codes::Playback::CUE,
            Codes::Playback::INTRO
          )

          CODES_TO_MARKERS = {
            Codes::Playback::POSITION => :position,
            Codes::Playback::CUE      => :cue,
            Codes::Playback::INTRO    => :intro
          }

          private

          def id
            CODES_TO_MARKERS[@response.code]
          end

          def ignore_response?
            find(player_url(id)).value == @response.position
          end

          def body
            create_model_object(:marker, id, @response.position)
          end
        end

        # Handler for BAPS2 channel loads
        class Load < LoaderHandler
          def_targets Codes::Playback::LOAD

          def id
            :item
          end

          def urls
            { insert:     player_url,
              kill:       player_url(:item),
              load_state: player_url(:load_state)
            }
          end

          def origin
            "playlist://#{@response.subcode}/#{@response.index}"
          end
        end
      end
    end
  end
end
