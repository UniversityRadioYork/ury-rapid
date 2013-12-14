require_relative 'handler.rb'
require_relative 'loader.rb'

module Bra
  module Baps
    module Responses
      module Handlers
        # Handles a BAPS playlist item removal, as well as full-playlist reset
        class Delete < Handler
          TARGETS = [
            Codes::Playlist::DELETE_ITEM,
            Codes::Playlist::RESET
          ]

          def run(response)
            delete(playlist_url(response, *sub_url(response)))
          end

          def sub_url(response)
            case response[:target]
            when Codes::Playlist::DELETE_ITEM
              [response[:index]]
            when Codes::Playlist::RESET
              []
            end
          end
        end

        class ItemCount < Handler
          TARGETS = [Codes::Playlist::ITEM_COUNT]

          def run(_)
            # No operation
          end
        end

        # Handles a BAPS playlist item add
        class ItemData < LoaderHandler
          TARGETS = [Codes::Playlist::ITEM_DATA]

          def id(response)
            response[:index]
          end

          def urls(response)
            { post: playlist_url(response) }
          end
        end
      end
    end
  end
end
