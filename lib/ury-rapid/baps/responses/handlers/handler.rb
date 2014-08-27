require 'ury-rapid/service_common/responses/handler'

module Rapid
  module Baps
    module Responses
      module Handlers
        # Extension to normal response handlers, including BAPS specific
        # functions
        class Handler < Rapid::ServiceCommon::Responses::Handler
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
            channel_url('players', *args)
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
            channel_url('playlists', *args)
          end

          # Generates an URL to a channel-related object given a BAPS response
          #
          # The subcode of the BAPS response must be the target channel.
          #
          # @api private
          #
          # @param root [String] The prefix for the URL.
          # @param args [Array] A splat of additional model object IDs to form
          #   a sub-URL of the player URL; optional.
          #
          # @return [String] The full model URL.
          def channel_url(root, *args)
            [root, @response.subcode, *args].join('/')
          end
        end
      end
    end
  end
end
