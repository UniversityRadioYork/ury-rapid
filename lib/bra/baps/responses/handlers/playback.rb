require_relative 'handler.rb'
require_relative 'loader.rb'

module Bra
  module Baps
    module Responses
      module Handlers
        # Handles a BAPS channel state change
        class State < Handler
          TARGETS = [
            Codes::Playback::PLAY,
            Codes::Playback::PAUSE,
            Codes::Playback::STOP
          ]

          CODES_TO_STATES = {
            Codes::Playback::PLAY  => :playing,
            Codes::Playback::PAUSE => :paused,
            Codes::Playback::STOP  => :stopped
          }

          def run(response)
            put(player_url(response, 'state'), state(response))
          end

          private

          def state(response)
            CODES_TO_STATES[response[:code]]
          end
        end

        # Handles a BAPS channel marker change
        class Marker < Handler
          TARGETS = [
            Codes::Playback::POSITION,
            Codes::Playback::CUE,
            Codes::Playback::INTRO
          ]

          CODES_TO_MARKERS = {
            Codes::Playback::POSITION => :position,
            Codes::Playback::CUE      => :cue,
            Codes::Playback::INTRO    => :intro,
          }

          def run(response)
            put(player_url(response, marker(response)), response[:position])
          end

          private

          def marker(response)
            CODES_TO_MARKERS[response[:code]]
          end
        end

        # Handles a BAPS item load
        class Load < LoaderHandler
          TARGETS = [
            Codes::Playback::LOAD
          ]

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
            "playlist://#{response[:subcode]}/#{response[:index]}"
          end
        end
      end
    end
  end
end
