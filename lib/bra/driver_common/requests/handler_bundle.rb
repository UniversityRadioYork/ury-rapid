require 'bra/driver_common/requests/handler'
require 'bra/driver_common/requests/player_handler'
require 'bra/driver_common/requests/playlist_handler'

module Bra
  module DriverCommon
    module Requests
      module HandlerBundle
        # Constructs a new handler
        def handler(name, *targets, &block)
          handler_with_class(Handler, name, *targets, &block)
        end

        # Constructs a new player handler
        def player_handler(name, *targets, &block)
          handler_with_class(PlayerHandler, name, *targets, &block)
        end

        # Constructs a new playlist handler
        def playlist_handler(name, *targets, &block)
          handler_with_class(PlaylistHandler, name, *targets, &block)
        end

        private

        # Constructs a new handler with the given arguments
        def handler_with_class(base_class, name, *targets, &block)
          cls = Class.new(base_class) do
            def_targets(*targets)

            class_eval(&block)
          end
          const_set(name, cls)
        end
      end
    end
  end
end
