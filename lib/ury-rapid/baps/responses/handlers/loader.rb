require 'ury-rapid/model'
require 'ury-rapid/baps/responses/handlers/handler'
require 'ury-rapid/baps/exceptions'

module Rapid
  module Baps
    module Responses
      module Handlers
        # Base class for handlers that wrap a Loader.
        #
        # Descendants should define methods id and urls,
        # which take the response and return the relevant Loader arguments.
        class LoaderHandler < Handler
          def run
            Loader.load(
              self,
              @response,
              id,
              urls,
              origin
            )
          end

          # Returns the origin of an item
          #
          # This defaults to nil.  Subclasses may override this to provide an
          # appropriate origin URL for the item.
          #
          # @return [NilClass] nil.
          def origin
            nil
          end
        end

        # A method object for loading an Item object into the model
        class ItemLoader
          # Stop handler loaders from trying to load handlers from this class.
          def self.targets?
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
            @parent.delete_if_exists(@urls[:delete])
          end

          def post
            @parent.post(@urls[:post], @id, @item)
          end

          def set_load_state
            @parent.put(@urls[:load_state], @load_state)
          end
        end

        # A method object for updating the Rapid model with BAPS track loads
        class Loader
          extend Forwardable

          # Stop handler loaders from trying to load handlers from this class.
          def self.targets?
            false
          end

          def self.load(*args)
            new(*args).run
          end

          def initialize(parent, response, id, urls, origin)
            @parent = parent
            @response = response
            @id = id
            @urls = urls
            @origin = origin
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

            [item, load_state_to_constant(load_state)]
          end

          def load_state_to_constant(load_state)
            @parent.create_model_object(:load_state, load_state)
          end

          def normal_load_state(load_state)
            load_state == :ok
          end

          def_delegators :@response, :type, :title, :duration

          def decide_load_state
            expecting_abnormal_load_state? ? load_state_from_title : :ok
          end

          def expecting_abnormal_load_state?
            # All of BAPS's non-OK load states occur when there is no real
            # item forthcoming.
            type == Types::Track::VOID
          end

          # Returns the load state implied by the track name
          #
          # This is necessary because of the rather odd way in which BAPS
          # signifies loading states other than :ok (that is, inside the track
          # name).
          #
          # @return [Symbol] One of the valid load states.
          def load_state_from_title
            TITLE_TO_ABNORMAL_LOAD_STATE[title] || :ok
          end

          # Hash mapping BAPS's special track titles to abnormal load states.
          TITLE_TO_ABNORMAL_LOAD_STATE = {
            '--LOADING--'     => :loading,
            '--LOAD FAILED--' => :failed,
            '--NONE--'        => :empty
          }

          # Hash mapping BAPS track type numbers to Rapid symbols.
          TRACK_TYPE_MAP = {
            Types::Track::LIBRARY => :library,
            Types::Track::FILE    => :file,
            Types::Track::TEXT    => :text
          }

          # Loads an item using an ItemLoader
          def load_item(item, load_state)
            ItemLoader.load(@parent, @id, item, load_state, @urls)
          end

          # Makes an item from the response
          #
          # @api private
          #
          # @return [Item] The item
          def make_item
            Rapid::Model::Item.new(
              type_as_bra_symbol, title, @origin, duration
            ).tap(&@parent.method(:register))
          end

          # Converts a BAPS track type to a Rapid track type
          #
          # @api private
          #
          # @return [Symbol] The Rapid equivalent of the BAPS track type
          #   (:library, :file or :text).
          def type_as_bra_symbol
            TRACK_TYPE_MAP.include?(type) ? TRACK_TYPE_MAP[type] : bad_type
          end

          def bad_type
            fail(Baps::Exceptions::InvalidTrackType, type)
          end
        end
      end
    end
  end
end
