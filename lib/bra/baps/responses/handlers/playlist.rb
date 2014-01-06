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
          def run
            delete(playlist_url(*sub_url))
          end
        end

        # Handles a BAPS playlist item removal
        class DeleteItem < Delete
          def_targets Codes::Playlist::DELETE_ITEM

          def sub_url
            [@response.index]
          end
        end

        # Handles a BAPS full playlist delete
        class DeletePlaylist < Delete
          def_targets Codes::Playlist::RESET

          def sub_url
            []
          end
        end

        # Handles a BAPS item count
        class ItemCount < Handler
          def_targets Codes::Playlist::ITEM_COUNT

          def run
            # No operation
          end
        end

        # Handles a BAPS playlist item add
        class ItemData < LoaderHandler
          def_targets Codes::Playlist::ITEM_DATA

          def id
            @response.index
          end

          def urls
            { post: playlist_url }
          end
        end

        # Handles a BAPS item movement
        class MoveItemInPlaylist < Handler
          def_targets Codes::Playlist::MOVE_ITEM_IN_PLAYLIST

          def run
            move if @response.new_index != @response.old_index
          end

          # Moves the item pointed to by response to its new index
          def move
            # Noting that post, if applied to an existing resource, moves it
            # to its new URL.
            post_item(get_item)
          end

          private

          # Posts the item into its new position
          def post_item(item)
            post(playlist_url, @response.new_index, item)
          end

          # Gets the item that wants to be moved
          def get_item
            get(playlist_url(@response.old_index))
          end

          # Calculates the URL to which the item shall be posted
          def new_url
            playlist_url(@response.new_index)
          end
        end
      end
    end
  end
end
