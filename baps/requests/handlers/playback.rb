require_relative '../handler'

module Bra
  module Baps
    module Requests
      module Handlers
        # Handler for channel players.
        class Player < Handler
          TARGETS = [:player]

          def post(object, payload)
            # TODO(mattbw): Cases other than {"item": ...}
            item = payload[:item]
            if item.is_a?(String)
              protocol, url = item.split('://')
              case protocol
              when 'playlist'
                send(
                  Request
                  .new(Codes::Playback::LOAD, object.channel_id)
                  .uint32(url.to_i)
                )
              else
                fail("Unsupported protocol: #{protocol}")
              end
            end
          end
        end

        # Handler for player position changes.
        class Position < VariableHandler
          # The handler targets matched by this handler.
          TARGETS = [:player_position]

          # Requests a PUT on the given player position via the BAPS server
          #
          # This changes the player position to that specified by new_position,
          # provided the position is valid.
          #
          # @api semipublic
          #
          # @example Set player state to playing via BAPS.
          #   playback_requester.put_state(state, :playing)
          # 
          # @param object [PlayerVariable] A player position model object.
          # @param new_position [Integer] The intended new player position.
          # 
          # @return [Boolean] false, to instruct the model not to update itself.
          def put(object, new_position)
            channel_id = object.player_channel_id
            send(
              Request
              .new(Codes::Playback::POSITION, channel_id)
              .uint32(Integer(new_position))
            )

            false
          end
        end

        # Handler for state changes.
        class StateHandler < VariableHandler
          # The handler targets matched by this handler.
          TARGETS = [:player_state]

          # Requests a PUT on the given player state via the BAPS server
          #
          # This changes the player state to that specified by new_state,
          # provided the state transition is valid.
          #
          # @api semipublic
          #
          # @example Set player state to playing via BAPS.
          #   playback_requester.put_state(state, :playing)
          # 
          # @param object [PlayerState] A player state model object.
          # @param new_state [Symbol] The intended new player state.  May be a
          #   string, in which case the string is converted to a symbol.
          # 
          # @return [Boolean] false, to instruct the model not to update itself.
          def put(object, new_state)
            channel_id = object.player_channel_id
            code_for_state(object.value, new_state).try do |command|
              send(Request.new(command, channel_id))
            end

            false
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

            [from, to].each(&Bra::Models::PlayerVariable.method(:validate_state))
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
