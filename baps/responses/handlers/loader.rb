require_relative 'handler'
require_relative '../../exceptions'

module Bra
  module Baps
    module Responses
      module Handlers
        # Base class for handlers that wrap a Loader.
        #
        # Descendants should define methods id and urls,
        # which take the response and return the relevant Loader arguments.
        class LoaderHandler < Handler
          def run(response)
            Loader.load(
              self,
              response,
              id(response),
              urls(response),
            )
          end
        end

        # A method object for loading an Item object into the model
        class ItemLoader
          # Stop handler loaders from trying to load handlers from this class.
          def self.has_targets?
            false
          end

          def self.load(*args)
            new(*args).run
          end

          def initialize(parent, id, item, load_state, urls)
            @parent = parent
            @id = id
            @item = item
            @load_state = load_state
            @urls = urls
          end

          def run
            post_or_delete if @urls[:post] || @urls[:delete]
            set_load_state if @urls[:load_state]
          end

          def post_or_delete
            @item.nil? ? delete : post
          end

          def delete
            @parent.delete(@urls[:delete])
          end

          def post
            @parent.post(@urls[:post], @id, @item)
          end

          def set_load_state
            @parent.put(@urls[:load_state], @load_state)
          end
        end

        # A method object for updating the bra model with BAPS track loads
        class Loader
          # Stop handler loaders from trying to load handlers from this class.
          def self.has_targets?
            false
          end

          def self.load(*args)
            new(*args).run
          end

          def initialize(parent, response, id, urls)
            @parent = parent
            @response = response
            @id = id
            @urls = urls

            extract_fields_from_response
          end

          def run
            load_item(*response_to_item_and_load_state)
          end

          private

          # Converts a `loaded' response into a pair of load-state and item
          #
          # @api private
          #
          # @param response [Hash] The loaded response to convert.
          #
          # @return [Array] The following items:
          #   - The loading state (:ok, :loading, :empty or :failed);
          #   - Either nil (no loaded item) or an Item representing the loaded
          #     item.
          def response_to_item_and_load_state
            load_state = decide_load_state
            item = make_item if normal_load_state(load_state)

            [item, load_state]
          end

          def normal_load_state(load_state)
            load_state == :ok
          end

          def extract_fields_from_response
            @type, @title, @duration = @response.values_at(
              :type, :title, :duration
            )
          end

          def decide_load_state
            expecting_abnormal_load_state? ? load_state_from_title : :ok
          end

          def expecting_abnormal_load_state?
            # All of BAPS's non-OK load states occur when there is no real
            # item forthcoming.
            @type == Types::Track::VOID
          end

          # Returns the load state implied by the track name
          #
          # This is necessary because of the rather odd way in which BAPS
          # signifies loading states other than :ok (that is, inside the track
          # name).
          #
          # @return [Symbol] One of the valid load states.
          def load_state_from_title
            TITLE_TO_ABNORMAL_LOAD_STATE[@title] || :ok
          end

          # Hash mapping BAPS's special track titles to abnormal load states.
          TITLE_TO_ABNORMAL_LOAD_STATE = {
            '--LOADING--'     => :loading,
            '--LOAD FAILED--' => :failed,
            '--NONE--'        => :empty
          }

          # Hash mapping BAPS track type numbers to BRA symbols.
          TRACK_TYPE_MAP = {
            Types::Track::LIBRARY => :library,
            Types::Track::FILE    => :file,
            Types::Track::TEXT    => :text
          }

          # Loads an item using an ItemLoader
          def load_item(item, load_state)
            ItemLoader.load(@parent, @id, item, load_state, @urls)
          end

          # Processes a normal loaded item response
          #
          # This converts the response into an item and possibly a duration
          # change.
          #
          # @api private
          #
          # @return [Hash] The item, wrapped in a POST payload.
          def make_item
            Bra::Models::Item.new(type_as_bra_symbol, @title)
          end

          # Converts a BAPS track type to a BRA track type
          #
          # @api private
          #
          # @return [Symbol] The bra equivalent of the BAPS track type
          #   (:library, :file or :text).
          def type_as_bra_symbol
            TRACK_TYPE_MAP.include?(@type) ? TRACK_TYPE_MAP[@type] : bad_type
          end

          def bad_type
            fail(Baps::Exceptions::InvalidTrackType, @type)
          end
        end
      end
    end
  end
end
