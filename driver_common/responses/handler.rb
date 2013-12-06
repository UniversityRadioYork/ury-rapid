require_relative '../handler'

module Bra
  module DriverCommon
    module Requests
      # Abstract class for handlers for a given model object
      #
      # Handlers are installed on model objects so that, when the server
      # attempts to modify the model object, the handler translates it into a
      # playout system command to perform the actual playout system event the
      # model change represents.
      class Handler < Bra::DriverCommon::Handler
        extend Forwardable

        def initialize(parent)
          super(parent)
          @model = parent.model
        end

        protected

        # Shorthand for @model.driver_X_url.
        def_delegator(:@model, :driver_put_url, :put)
        def_delegator(:@model, :driver_post_url, :post)
        def_delegator(:@model, :driver_delete_url, :delete)

        # Generates an URL to a channel player given a BAPS response
        #
        # The subcode of the BAPS response must be the target channel.
        #
        # @api private
        #
        # @param response [Hash] The response mentioning the channel to use.
        # @param args [Array] A splat of additional model object IDs to form a
        #   sub-URL of the player URL; optional.
        #
        # @return [String] The full model URL.
        def player_url(response, *args)
          channel_url(response, 'player', *args)
        end

        # Generates an URL to a channel playlist given a BAPS response
        #
        # The subcode of the BAPS response must be the target channel.
        #
        # @api private
        #
        # @param response [Hash] The response mentioning the channel to use.
        # @param args [Array] A splat of additional model object IDs to form a
        #   sub-URL of the playlist URL; optional.
        #
        # @return [String] The full model URL.
        def playlist_url(response, *args)
          channel_url(response, 'playlist', *args)
        end

        # Generates an URL to a channel given a BAPS response
        #
        # The subcode of the BAPS response must be the target channel.
        #
        # @api private
        #
        # @param response [Hash] The response mentioning the channel to use.
        # @param args [Array] A splat of additional model object IDs to form a
        #   sub-URL of the player URL; optional.
        #
        # @return [String] The full model URL.
        def channel_url(response, *args)
          ['channels', response[:subcode], *args].join('/')
        end
      end
    end
  end
end
