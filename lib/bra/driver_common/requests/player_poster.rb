require_relative 'poster'

module Bra
  module DriverCommon
    module Requests
      # Abstract object for handling POSTs in Player objects
      #
      # This deals with the various protocols POSTing objects handles, so that
      # drivers can override the protocol methods they implement
      class PlayerPoster < Poster
        extend Forwardable

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

        def_delegator :@object, :id, :player_id

        # Determines whether a payload should be forwarded somewhere else
        #
        # This makes payloads this Poster isn't responsible for be sent to the
        # Player's children as PUT requests.
        #
        # @return [Boolean]  True if this Poster handles this payload; false if
        #   the payload should be sent on as a PUT request.
        def post_forward
          payload_id == :item ? false : super()
        end

        # Set up the main Poster methods to reference the jump tables above
        %w{url hash}.each do |type|
          jump_table = const_get("#{type.upcase}_TYPES")
          jump_table.default = :unsupported_protocol

          # Assume nothing other than :item reaches here.
          define_method("post_#{type}") do |type, rest|
            send(jump_table[type], rest)
          end
        end

        # Set up stubs for each method we expect the driver to override.
        TO_OVERRIDE.each do |method_symbol|
          define_method(method_symbol) do |*args|
            fail(Bra::Exceptions::NotSupportedByDriver)
          end
        end

        protected

        # Handles a server POST of an item from a playlist, expressed as a Hash
        def item_from_playlist_hash(hash)
          playlist   = hash[:playlist]
          playlist ||= object_id
          index      = hash[:index]
          index    ||= 0

          item_from_playlist(playlist, index.to_i)
        end

        # Handles a server POST of an item from a playlist, expressed as a URL
        def item_from_playlist_url(url)
          split = url.split('/', 2)
          playlist, index = object_id, split.first if split.size == 1
          playlist, index = split                  if split.size == 2
          fail('Bad playlist URL.')                if split.size > 2

          item_from_playlist(playlist, index.to_i)
        end

        def item_from_playlist(playlist, index)
          ( is_local_playlist?(playlist) ?
            item_from_local_playlist(index) :
            item_from_other_playlist(playlist, index)
          )
        end

        # @return [Boolean] True if the playlist ID is the same as the player
        #   ID.
        def is_local_playlist?(playlist)
          object_id == playlist || object_id.to_s == playlist
        end
      end
    end
  end
end
