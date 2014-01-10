require 'bra/common/types'
require 'bra/driver_common/requests/handler'
require 'bra/driver_common/requests/player_handler'

module Bra
  module Baps
    module Requests
      module Handlers
        # Handler for channel players
        class Player < Bra::DriverCommon::Requests::PlayerHandler
          def_targets :player

          def item_from_local_playlist(index)
            request(
              Request.new(Codes::Playback::LOAD, caller_id).uint32(index)
            )
          end
        end

        # Handler for player volume changes.
        class Volume < Bra::DriverCommon::Requests::VariableHandler
          def_targets :volume
          put_by_payload_processor

          def float(float)
            request(
              Request.new(Codes::Playback::VOLUME, caller_parent_id)
                     .float32(float)
            )
          end
        end

        # Handler for player marker changes.
        class Marker < Bra::DriverCommon::Requests::VariableHandler
          def_targets :position, :cue, :intro
          put_by_payload_processor

          def integer(integer)
            request(
              Request.new(target_to_code, caller_parent_id).uint32(integer)
            )
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
        class State < Bra::DriverCommon::Requests::VariableHandler
          def_targets :state
          put_by_payload_processor

          include Bra::Common::Types::Validators

          def string(new_state)
            code_for_state(@object.value, new_state).try do |command|
              request(Request.new(command, caller_parent_id))
            end
          end

          private

          # Converts a state change to a BAPS command code
          #
          # @api private
          #
          # @param from [Symbol] The bra state from which we are switching.
          # @param to [Symbol] The bra state to which we are switching.
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
              # little sense, and bra disallows it, so we ignore it.
              playing: Codes::Playback::PLAY,
            }
          }
        end
      end
    end
  end
end
