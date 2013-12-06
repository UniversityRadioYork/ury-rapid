module Bra
  module Baps
    module Responses
      module Handlers
        # Base class for handlers that wrap a Loader.
        #
        # Descendants should define methods post_url, id and load_state_url,
        # which take the response and return the relevant Loader arguments.
        class LoaderHandler < Bra::DriverCommon::Responses::Handler
          def run(response)
            Loader.load(
              self,
              response,
              post_url(response),
              id,
              load_state_url(response)
            )
          end
        end

        # A method object for loading an Item object into the model
        class ItemLoader
          def self.load(*args)
            new(*args).run
          end

          def initialize(parent, item, load_state, post_url, load_state_url)
            @parent = parent
            @item = item
            @load_state = load_state
            @post_url = post_url
            @load_state_url = load_state_url

            extract_fields_from_response
          end

          def run
            post_or_delete if @post_url
            set_load_state if @load_state_url
          end

          def post_or_delete
            @item.nil? ? delete : post
          end

          def delete
            parent.delete(@post_url)
          end

          def post
            @parent.post(@post_url, @item)
          end

          def set_load_state
            @parent.put(load_state_url, @load_state)
          end
        end

        # A method object for updating the bra model with BAPS track loads
        class Loader
          def self.load(*args)
            new(*args).run
          end

          def initialize(parent, response, post_url, id, load_state_url)
            @parent = parent
            @response = response
            @post_url = post_url
            @load_state_url = load_state_url
            @id = id
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
            load_state = load_state_from_title
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

          # Returns the load state implied by the track name
          #
          # This is necessary because of the rather odd way in which BAPS
          # signifies loading states other than :ok (that is, inside the track
          # name).
          #
          # @return [Symbol] One of the valid load states.
          def load_state_from_title(title)
            TITLE_TO_ABNORMAL_LOAD_STATE[title] || :ok
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
            ItemLoader.load(
              @parent, item, load_state, @post_url, @load_state_url
            )
          end

          # Processes a normal loaded item response
          #
          # This converts the response into an item and possibly a duration change.
          #
          # @api private
          #
          # @return [Hash] The item, wrapped in a POST payload.
          def make_item
            { @id => Bra::Models::Item.new(type_as_bra_symbol, @title) }
          end

          # Converts a BAPS track type to a BRA track type
          #
          # @api private
          #
          # @return [Symbol] The bra equivalent of the BAPS track type (:library,
          #   :file or :text).
          def type_as_bra_symbol
            fail(InvalidTrackType, @type) unless TRACK_TYPE_MAP.include? @type
            TRACK_TYPE_MAP[@type]
          end
        end

        InvalidTrackType = Class.new(RuntimeError)
      end
    end

  end
end
