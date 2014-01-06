require 'bra/driver_common/requests/url_hash_handler'

module Bra
  module DriverCommon
    module Requests
      module Handlers
        # Base class for handlers that handle requests on playlists
        # 
        # This provides boilerplate code for working with the standard bra
        # playlist API.
        class PlaylistHandler < UrlHashHandler
          use_payload_processor_for :post
          put_by_posting_to_parent
        end
      end
    end
  end
end

