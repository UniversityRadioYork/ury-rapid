require 'bra/baps/responses/handlers/handler'
require 'bra/baps/responses/handlers/loader'

module Bra
  module Baps
    module Responses
      module Handlers
        class PlayerHandler < Handler
          def run(response)
            do_post(response) unless ignore_response?(response)
          end

          protected

          def ignore_response?(response)
            false
          end

          def do_post(response)
            post(player_url(response), id(response), body(response))
          end
        end

        # Handles a BAPS channel state change
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

          def id(response)
            :state
          end

          def ignore_response?(response)
            get(player_url(response, id(response))).value == state(response)
          end

          def body(response)
            create_model_object(:play_state, state(response))
          end

          def state(response)
            CODES_TO_STATES[response.code]
          end
        end

        class Volume < PlayerHandler
          def_targets Codes::Playback::VOLUME

          private

          def id(response)
            :volume
          end

          def ignore_response?(response)
            get(player_url(response, id(response))).value == response.volume
          end

          def body(response)
            create_model_object(:volume, response.volume)
          end
        end

        # Handles a BAPS channel marker change
        class Marker < PlayerHandler
          def_targets(
            Codes::Playback::POSITION,
            Codes::Playback::CUE,
            Codes::Playback::INTRO
          )

          CODES_TO_MARKERS = {
            Codes::Playback::POSITION => :position,
            Codes::Playback::CUE      => :cue,
            Codes::Playback::INTRO    => :intro,
          }

          private

          def id(response)
            CODES_TO_MARKERS[response.code]
          end

          def ignore_response?(response)
            get(player_url(response, id(response))).value == response.position
          end

          def body(response)
            create_model_object(:marker, id(response), response.position)
          end
        end

        # Handles a BAPS item load
        class Load < LoaderHandler
          def_targets Codes::Playback::LOAD

          def id(response)
            :item
          end

          def urls(response)
            { post:       player_url(response),
              delete:     player_url(response, :item),
              load_state: player_url(response, :load_state)
            }
          end

          def origin(response)
            "playlist://#{response.subcode}/#{response.index}"
          end
        end
      end
    end
  end
end
