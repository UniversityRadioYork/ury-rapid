require 'bra/baps/responses/handlers/handler'
require 'bra/baps/responses/handlers/loader'

module Bra
  module Baps
    module Responses
      module Handlers
        # Abstract class for playlist deletion handlers
        #
        # Subclasses should define sub_url, which defines the URL path from
        # the playlist that should be deleted.
        class Delete < Handler
          def run(response)
            delete(playlist_url(response, *sub_url(response)))
          end
        end

        # Handles a BAPS playlist item removal
        class DeleteItem < Delete
          TARGETS = [Codes::Playlist::DELETE_ITEM]

          def sub_url(response)
            [response[:index]]
          end
        end

        # Handles a BAPS full playlist delete
        class DeletePlaylist < Delete
          TARGETS = [Codes::Playlist::RESET]

          def sub_url(response)
            []
          end
        end

        # Handles a BAPS item count
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

        # Handles a BAPS item movement
        class MoveItemInPlaylist < Handler
          TARGETS = [Codes::Playlist::MOVE_ITEM_IN_PLAYLIST]

          def run(response)
            new_index, old_index = response.values_at(:new_index, :old_index)

            move(response, new_index) if new_index != old_index
          end

          # Moves the item pointed to by response to its new index
          def move(response, new_index)
            # Noting that post, if applied to an existing resource, moves it
            # to its new URL.
            url = new_url(response, new_index)
            get_item(response) { |item| post(url, item) }
          end

          private

          # Gets the item that wants to be moved and yields it to a block
          def get_item(response, &block)
            find_url(playlist_url(response, response[:old_index]), &block)
          end

          # Calculates the URL to which the item shall be posted
          def new_url(response, new_index)
            playlist_url(response, new_index)
          end
        end
      end
    end
  end
end
