require_relative 'loader.rb'

module Bra
  module Baps
    module Responses
      module Handlers
        # Handles a BAPS playlist item removal, as well as full-playlist reset
        class Delete < Bra::DriverCommon::Responses::Handler
          TARGETS = [
            Codes::Playback::DELETE_ITEM,
            Codes::Playback::RESET
          ]

          def run(response)
            delete(playlist_url(response, *sub_url(response)))
          end

          def sub_url(response)
            case response[:target]
            when Codes::Playback::DELETE_ITEM
              [response[:index]]
            when Codes::Playback::RESET
              []
            end
          end
        end

        class ItemCount < LoadHandler
          TARGETS = [Codes::Playback::LOAD_COUNT]

          def run(_)
            # No operation
          end
        end

        # Handles a BAPS playlist item add
        class ItemData < LoadHandler
          TARGETS = [Codes::Playback::ITEM_DATA]

          alias_method :playlist_url, :post_url

          def id(response)
            response[:index]
          end

          def load_state_url(response)
            nil
          end
        end
      end
    end
  end
end
