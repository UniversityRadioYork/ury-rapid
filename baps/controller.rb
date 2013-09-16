require_relative 'codes'

module Bra
  module Baps
    # Internal: An object that responds to BAPS server responses by updating
    # the model.
    class Controller
      # Internal: Initialises the controllers.
      #
      # model - The Model this Controller will operate on.
      def initialize(model)
        @model = model
      end

      # Internal: Registers the controller's callbacks with a response
      # dispatch.
      #
      # dispatch - The object sending responses to listeners.
      #
      # Returns nothing.
      def register(dispatch)
        functions = [
          playback_functions,
          playlist_functions,
          system_functions
        ].reduce({}) { |a, e| a.merge! e }

        dispatch.register_response_handlers functions
      end

      # Public: Register playback response handler functions.
      #
      # Returns nothing.
      def playback_functions
        {
          Codes::Playback::PLAY => method(:playing),
          Codes::Playback::PAUSE => method(:paused),
          Codes::Playback::STOP => method(:stopped),
          Codes::Playback::POSITION => method(:position),
          Codes::Playback::CUE => method(:cue),
          Codes::Playback::INTRO => method(:intro),
          Codes::Playback::LOADED => method(:loaded)
        }
      end

      # Public: Register playlist response handler functions.
      #
      # Returns nothing.
      def playlist_functions
        {
          Codes::Playlist::ITEM_DATA => method(:item_data),
          Codes::Playlist::ITEM_COUNT => method(:item_count),
          Codes::Playlist::RESET => method(:reset)
        }
      end

      # Public: Register system response handler functions.
      #
      # Returns nothing.
      def system_functions
        {
          Codes::System::CLIENT_ADD => method(:client_add),
          Codes::System::CLIENT_REMOVE => method(:client_remove),
          Codes::System::LOG_MESSAGE => method(:log_message)
        }
      end

      private

      def playing(response)
        set_player_state(response, :playing)
      end

      def paused(response)
        set_player_state(response, :paused)
      end

      def stopped(response)
        set_player_state(response, :stopped)
      end

      def position(response)
        player_from(response).position = response[:position]
      end

      def cue(response)
        player_from(response).cue = response[:position]
      end

      def intro(response)
        player_from(response).intro = response[:position]
      end

      def set_player_state(response, state)
        @model.set_player_state(response[:subcode], state)
      end

      def item_data(response)
        id, index = response.values_at(:subcode, :index)
        type, title = response.values_at(:type, :title)
        item = Models::Item.new(track_type_baps_to_bra(type), title)

        @model.channel(id).add_item index, item
      end

      def reset(response)
        id = response[:subcode]
        @model.channel(id).clear_playlist
      end

      def loaded(response)
        @model.load_in_player(response[:subcode], *(loaded_item(response)))
      end

      def item_count(response)
        nil
      end

      def client_add(response)
        nil
      end

      def client_remove(response)
        nil
      end

      def log_message(response)
        # TODO: actually log this message
        puts "[LOG] #{response[:message]}"
      end

      # Internal: From a response, get the target channel player.
      #
      # response - The response whose subcode denotes the correct channel.
      #
      # Returns a Player object which represents the requested channel's player
      #   model.
      def player_from(response)
        @model.player(response[:subcode])
      end

      # Internal: Converts an loaded response into a pair of load-state and
      # item.
      #
      # response - The loaded response to convert.
      #
      # Returns a list with the following items:
      #   - The loading state (:ok, :loading, :empty or :failed);
      #   - Either nil (no loaded item) or an Item representing the loaded
      #     item.
      def loaded_item(response)
        type, title, duration = response.values_at :type, :title, :duration
        @model.channel(response[:subcode]).duration = duration if duration.nil?

        pair = SPECIAL_LOAD_STATES[title]
        pair ||= normal_loaded_item(type, title)
      end

      # Internal: Processes a normal loaded item response, converting it into
      # an item and possibly a duration change.
      #
      # type     - The item type (one of :library, :file or :text).
      # title    - The title to display for the item.
      # duration - Nil, or the duration of the loaded item.
      #
      # Returns a list with the following items:
      #   - The loading state (:ok, :loading, :empty or :failed);
      #   - Either nil (no loaded item) or an Item representing the loaded
      #     item.
      def normal_loaded_item(type, title)
        [:ok, Models::Item.new(track_type_baps_to_bra(type), title)]
      end

      # Internal: Converts a BAPS track type to a BRA track type.
      #
      # type - The BAPS track type number.  Must NOT be Types::Track::NULL.
      #
      # Returns a symbol (:library, :file or :text) being the BRA equivalent of
      # the BAPS track type.
      def track_type_baps_to_bra(type)
        raise InvalidTrackType, type unless TRACK_TYPE_MAP.include? type
        TRACK_TYPE_MAP[type]
      end

      # Internal: Hash mapping special load state names to pairs of BRA load
      # states and item representations.
      #
      # This is necessary because of the rather odd way in which BAPS signifies
      # loading states other than :ok (that is, inside the track name!).
      SPECIAL_LOAD_STATES = {
        '--LOADING--' => [:loading, nil],
        '--LOAD FAILED--' => [:failed, nil],
        '--NONE--' => [:empty, nil]
      }

      # Internal: Hash mapping BAPS track type numbers to BRA symbols.
      TRACK_TYPE_MAP = {
        Types::Track::LIBRARY => :library,
        Types::Track::FILE => :file,
        Types::Track::TEXT => :text
      }
    end
  end
end
