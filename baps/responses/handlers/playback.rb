require_relative 'loader.rb'

module Bra
  module Baps
    module Responses
      module Handlers
        # Handles a BAPS channel state change
        class State < Bra::DriverCommon::Responses::Handler
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

        # Handles a BAPS channel state change
        class Marker < Bra::DriverCommon::Responses::Handler
          TARGETS = [
            Codes::Playback::POSITION
            Codes::Playback::CUE
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
            CODES_TO_MARKER[response[:code]]
          end
        end

        # Handles a BAPS item load
        class Load < Bra::DriverCommon::Responses::Handler
          TARGETS = [Codes::Playback::LOAD]

          alias_method :player_url, :post_url

          def id(response)
            response[:index]
          end

          def load_state_url(response)
            player_url(response, :load_state)
          end
        end
      end
    end
  end
end
