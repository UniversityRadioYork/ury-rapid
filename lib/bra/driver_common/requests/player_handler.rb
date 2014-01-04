require 'bra/driver_common/requests/poster'

module Bra
  module DriverCommon
    module Requests
      # Extension of request handler to deal with the common Player APIs
      #
      # This deals with the various protocols for POSTing player items, so that
      # drivers can override the protocol methods they implement
      class PlayerHandler < Handler
        use_post_payload_processor

        # Supported URL protocols in this version of the bra API.
        URL_TYPES = {
          playlist: :item_from_playlist_url
        }

        # Supported hash types in this version of the bra API.
        HASH_TYPES = {
          playlist: :item_from_playlist_hash
        }

        # These are the overridable functions a concrete PlayerPoster can fill
        # in.  They are defined in this class as raising a NotSupportedByDriver
        # exception.
        TO_OVERRIDE = [
          :item_from_local_playlist,  # index
          :item_from_other_playlist   # playlist_id, index
        ]

        # Set up the main Poster methods to reference the jump tables above
        %w{url hash}.each do |style|
          jump_table = const_get("#{style.upcase}_TYPES")
          jump_table.default = :unsupported_protocol

          # Assume nothing other than :item reaches here.
          define_method(style) do |type, rest|
            send(jump_table[type], rest)
          end
        end

        # Set up stubs for each method we expect the driver to override.
        TO_OVERRIDE.each do |method_symbol|
          define_method(method_symbol) do |*args|
            fail(Bra::Common::Exceptions::NotSupportedByDriver)
          end
        end

        protected

        # Handles a server POST of an item from a playlist, expressed as a Hash
        def item_from_playlist_hash(hash)
          playlist   = hash[:playlist]
          playlist ||= caller_id
          index      = hash[:index]
          index    ||= 0

          item_from_playlist(playlist, index.to_i)
        end

        # Handles a server POST of an item from a playlist, expressed as a URL
        def item_from_playlist_url(url)
          split = url.split('/', 2)
          playlist, index = caller_id, split.first if split.size == 1
          playlist, index = split                  if split.size == 2
          fail('Bad playlist URL.')                if split.size > 2

          item_from_playlist(playlist, index.to_i)
        end

        def item_from_playlist(playlist, index)
          local = is_local_playlist?(playlist)
          item_from_local_playlist(index)           if local
          item_from_other_playlist(playlist, index) unless local
        end

        # @return [Boolean] True if the playlist ID is the same as the player
        #   ID.
        def is_local_playlist?(playlist)
          caller_id == playlist || caller_id.to_s == playlist
        end
      end
    end
  end
end
