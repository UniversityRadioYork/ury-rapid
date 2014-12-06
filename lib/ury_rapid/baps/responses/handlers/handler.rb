require 'ury_rapid/services/responses/handler'

module Rapid
  module Baps
    module Responses
      module Handlers
        # Extension to normal response handlers, including BAPS specific
        # functions
        class Handler < Rapid::Services::Responses::Handler
          protected

          # Generates an URL to a channel player given a BAPS response
          #
          # The subcode of the BAPS response must be the target channel.
          #
          # @api private
          #
          # @param args [Array] A splat of additional model object IDs to form
          #   a sub-URL of the player URL; optional.
          #
          # @return [String] The full model URL.
          def player_url(*args)
            channel_url('player', *args)
          end

          # Generates an URL to a channel playlist given a BAPS response
          #
          # The subcode of the BAPS response must be the target channel.
          #
          # @api private
          #
          # @param args [Array] A splat of additional model object IDs to form
          #   a sub-URL of the playlist URL; optional.
          #
          # @return [String] The full model URL.
          def playlist_url(*args)
            channel_url('playlist', *args)
          end

          # Generates an URL to a channel-related object given a BAPS response
          #
          # The subcode of the BAPS response must be the target channel.
          #
          # @api private
          #
          # @param args [Array] A splat of additional model object IDs to form
          #   a sub-URL of the channel URL; optional.
          #
          # @return [String] The full model URL.
          def channel_url(*args)
            ['channels', @response.subcode, *args].join('/')
          end
        end
      end
    end
  end
end
