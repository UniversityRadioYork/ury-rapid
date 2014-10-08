require 'ury_rapid/common/types'
require 'ury_rapid/service_common/requests/handler_bundle'

module Rapid
  module Baps
    module Requests
      module Handlers
        extend Rapid::ServiceCommon::Requests::HandlerBundle

        player_handler 'Player', :player do
          def item_from_local_playlist(index)
            request Codes::Playback::LOAD, caller_id do
              uint32 index
            end
          end
        end

        handler 'Volume', :volume do
          put_by_payload_processor

          def float(float)
            request Codes::Playback::VOLUME, caller_parent_id do
              float32 float
            end
          end
        end

        handler 'Marker', :position, :cue, :intro do
          put_by_payload_processor

          def integer(integer)
            request(target_to_code, caller_parent_id) { uint32 integer }
          end

          private

          def target_to_code
            TARGET_CODES.fetch(@object.handler_target)
          end

          TARGET_CODES = {
            position: Codes::Playback::POSITION,
            cue:      Codes::Playback::CUE,
            intro:    Codes::Playback::INTRO
          }
        end

        # Handler for state changes.
        handler 'State', :state do
          put_by_payload_processor

          include Rapid::Common::Types::Validators

          def string(new_state)
            code_for_state(@object.value, new_state).try do |command|
              request(command, caller_parent_id)
            end
          end

          private

          # Converts a state change to a BAPS command code
          #
          # @api private
          #
          # @param from [Symbol] The Rapid state from which we are switching.
          # @param to [Symbol] The Rapid state to which we are switching.
          #
          # @return [Integer] The BAPS command code that must be sent to effect
          #   the state change.
          def code_for_state(from, to)
            # Convert these to symbols, if they are currently strings.
            from = from.intern
            to = to.intern

            [from, to].each(&method(:validate_play_state))
            CODES[from][to]
          end

          # Mapping between state symbols and BAPS request codes.
          # Note that only valid, non-redundant transitions are defined.
          CODES = {
            playing: {
              paused: Codes::Playback::PAUSE,
              stopped: Codes::Playback::STOP
            },
            paused: {
              # The below is not a typo, it's how BAPS works...
              playing: Codes::Playback::PAUSE,
              stopped: Codes::Playback::STOP
            },
            stopped: {
              # BAPS allows us to pause while the song is stopped.  This makes
              # little sense, and Rapid disallows it, so we ignore it.
              playing: Codes::Playback::PLAY
            }
          }
        end
      end
    end
  end
end
