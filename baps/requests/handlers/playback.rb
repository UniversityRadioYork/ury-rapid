require_relative '../../../driver_common/requests/handler'
require_relative '../../../driver_common/requests/poster'

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
        end

        # A method object that handles POSTs to the Player for BAPS
        class PlayerPoster < Bra::DriverCommon::Requests::Poster
          def post_forward
            @payload.id == :item ? false : super()
          end

          def post_url(protocol, url)
            # TODO(mattbw): IDs other than :item.
            item_from_playlist_url(url)     if     protocol == :playlist
            unsupported_protocol(protocol)  unless protocol == :playlist
          end

          def post_hash(type, hash)
            # TODO(mattbw): IDs other than :item.
            item_from_playlist_hash(hash)   if     type == :playlist
            unsupported_protocol(type)      unless type == :playlist
          end

          private

          def channel_id
            @object.channel_id
          end

          def item_from_playlist_hash(hash)
            # TODO(mattbw): Non-local loads?
            # TODO(mattbw): Non-existent indices.
            item_from_local_playlist(hash[:index].to_i)
          end

          def item_from_playlist_url(url)
            item_from_local_playlist(url.to_i)
          end

          def item_from_local_playlist(index)
            request(
              Request.new(Codes::Playback::LOAD, channel_id).uint32(index)
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
          def post_integer(integer)
            request(Request .new(target_to_code, channel_id) .uint32(integer))
          end

          private

          def channel_id
            @object.player_channel_id
          end

          def target_to_code
            TARGET_CODES[@object.handler_target]
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
          def post_string(new_state)
            code_for_state(@object.value, new_state).try do |command|
              request(Request.new(command, channel_id))
            end
          end

          private

          def channel_id
            @object.player_channel_id
          end

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

            [from, to].each(
              &Bra::Models::PlayerVariable.method(:validate_state)
            )
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
