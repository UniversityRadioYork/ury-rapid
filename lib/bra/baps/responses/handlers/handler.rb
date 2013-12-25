require 'bra/driver_common/responses/handler'

module Bra
  module Baps
    module Responses
      module Handlers
        # Extension to normal response handlers, including BAPS specific
        # functions
        class Handler < Bra::DriverCommon::Responses::Handler

          protected

          # Generates an URL to a channel player given a BAPS response
          #
          # The subcode of the BAPS response must be the target channel.
          #
          # @api private
          #
          # @param response [Hash] The response mentioning the channel to use.
          # @param args [Array] A splat of additional model object IDs to form
          #   a sub-URL of the player URL; optional.
          #
          # @return [String] The full model URL.
          def player_url(response, *args)
            channel_url('players', response, *args)
          end

          # Generates an URL to a channel playlist given a BAPS response
          #
          # The subcode of the BAPS response must be the target channel.
          #
          # @api private
          #
          # @param response [Hash] The response mentioning the channel to use.
          # @param args [Array] A splat of additional model object IDs to form
          #   a sub-URL of the playlist URL; optional.
          #
          # @return [String] The full model URL.
          def playlist_url(response, *args)
            channel_url('playlists', response, *args)
          end

          # Generates an URL to a channel-related object given a BAPS response
          #
          # The subcode of the BAPS response must be the target channel.
          #
          # @api private
          #
          # @param root [String] The prefix for the URL.
          # @param response [Hash] The response mentioning the channel to use.
          # @param args [Array] A splat of additional model object IDs to form
          #   a sub-URL of the player URL; optional.
          #
          # @return [String] The full model URL.
          def channel_url(root, response, *args)
            [root, response.subcode, *args].join('/')
          end
        end
      end
    end
  end
end
