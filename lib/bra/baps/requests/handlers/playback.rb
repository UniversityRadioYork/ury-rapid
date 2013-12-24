require 'bra/common/types'
require 'bra/driver_common/requests/handler'
require 'bra/driver_common/requests/player_poster'
require 'bra/driver_common/requests/poster'

module Bra
  module Baps
    module Requests
      module Handlers
        # Handler for channel players
        class Player < Bra::DriverCommon::Requests::Handler
          # The handler targets matched by this handler.
          TARGETS = [:player]

          def post(object, payload)
            PlayerPoster.post(payload, self, object)
          end

          # Creates a handler for the item loaded into this Player
          def item_handler(object)
            LoadedItem.new(@parent)
          end
        end

        # Handler for loaded items
        class LoadedItem < Bra::DriverCommon::Requests::Handler
          # This handler has no targets - it is attached to incoming items
          # by the Player's handler.
          def delete(object, payload)
            fail(Bra::Common::Exceptions::NotSupportedByDriver)
          end
        end

        # A method object that handles POSTs to the Player for BAPS
        class PlayerPoster < Bra::DriverCommon::Requests::PlayerPoster
          def item_from_local_playlist(index)
            request(
              Request.new(Codes::Playback::LOAD, caller_id).uint32(index)
            )
          end
        end

        # Handler for player position changes.
        class Marker < Bra::DriverCommon::Requests::VariableHandler
          # The handler targets matched by this handler.
          TARGETS = [:player_position, :player_cue, :player_intro]

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
          # @return [void]
          def put(object, payload)
            MarkerPoster.post(payload, self, object)
          end
        end

        # Object that performs the POSTing and PUTting of a playback marker
        class MarkerPoster < Bra::DriverCommon::Requests::Poster
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
            player_position: Codes::Playback::POSITION,
            player_cue:      Codes::Playback::CUE,
            player_intro:    Codes::Playback::INTRO
          }
        end

        # Handler for state changes.
        class StateHandler < Bra::DriverCommon::Requests::VariableHandler
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
          # @return [void]
          def put(object, payload)
            StatePoster.post(payload, self, object)
          end
        end

        # Object that performs the POSTing and PUTting of a playback marker
        class StatePoster < Bra::DriverCommon::Requests::Poster
          extend Forwardable
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
