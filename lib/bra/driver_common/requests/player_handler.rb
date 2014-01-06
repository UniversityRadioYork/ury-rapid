require 'bra/driver_common/requests/handler'
require 'bra/driver_common/requests/url_hash_handler'

module Bra
  module DriverCommon
    module Requests
      # Extension of request handler to deal with the common Player APIs
      #
      # This deals with the various protocols for POSTing player items, so that
      # drivers can override the protocol methods they implement
      class PlayerHandler < UrlHashHandler
        use_payload_processor_for :post, :item
        post_by_putting_to_child_for :volume, :state, :load_state
        post_by_putting_to_child_for :position, :cue, :intro

        # Supported URL protocols in this version of the bra API.
        url_type :playlist do |url|
          item_from_playlist(*split_playlist_url(url))
        end

        # Supported hash types in this version of the bra API.
        hash_type :playlist do |hash|
          item_from_playlist(*get_location_from_hash(hash))
        end

        # These are the overridable functions a concrete PlayerPoster can fill
        # in.  They are defined in this class as raising a NotSupportedByDriver
        # exception.
        TO_OVERRIDE = [
          :item_from_local_playlist,  # index
          :item_from_other_playlist   # playlist_id, index
        ]

        # Set up stubs for each method we expect the driver to override.
        TO_OVERRIDE.each do |method_symbol|
          define_method(method_symbol) do |*args|
            fail(Bra::Common::Exceptions::NotSupportedByDriver)
          end
        end

        protected

        def split_playlist_url(url)
          split = url.split('/', 2)
          playlist, index = caller_id, split.first if split.size == 1
          playlist, index = split                  if split.size == 2
          fail('Bad playlist URL.')                if split.size > 2
          [playlist, index.to_i]
        end

        def get_location_from_hash(hash)
          playlist = hash[:playlist] || caller_id
          index    = hash[:index]    || 0
          [playlist, index.to_i]
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
