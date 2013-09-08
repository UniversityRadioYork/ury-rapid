require_relative 'codes'

module Bra
  module Baps
    # Internal: An object that responds to BAPS server responses by updating the
    # model.
    class Controller
      # Internal: Initialises the controllers.
      #
      # model - The Model this Controller will operate on.
      def initialize(model)
        @model = model
      end

      # Internal: Registers the controller's callbacks with a response dispatch.
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
        player_from(response).state = :playing
      end

      def paused(response)
        player_from(response).state = :paused
      end

      def stopped(response)
        player_from(response).state = :stopped
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

      def item_data(response)
        id, index = response.values_at(:subcode, :index)
        type, title = response.values_at(:type, :title)
        item = Item.new track_type_baps_to_bra(type), title

        @model.channel(id).add_item index, item
      end

      def reset(response)
        id = response[:subcode]
        @model.channel(id).clear_playlist
      end

      def loaded(response)
        player_from(response).load(*(loaded_item response))
      end

      def item_count(response)
        puts "[ITEM#] Channel: #{response[:subcode]} #{response[:count]} items"
      end

      def client_add(response)
        puts "[CLIENTCHANGE] Client #{response[:client]} appeared"
      end

      def client_remove(response)
        puts "[CLIENTCHANGE] Client #{response[:client]} disappeared"
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
        @model.channel(response[:subcode]).player
      end

      # Converts an loaded response into a pair of load-state and item.
      #
      # response - The loaded response to convert.
      #
      # Returns a list with the following items:
      #   - The loading state (:ok, :loading or :failed);
      #   - Either nil (no loaded item) or an Item representing the loaded item.
      def loaded_item(response)
        # Deal with BAPS's interesting way of encoding load states.
        case response[:title]
        when '--LOADING--'
          [:loading, nil]
        when '--LOAD FAILED--'
          [:failed, nil]
        when '--NONE--'
          [:empty, nil]
        else
          type, title = response.values_at(:type, :title)
          position response if response.key? :position
          [:ok, Item.new(track_type_baps_to_bra(type), title)]
        end
      end

      # Internal: Converts a BAPS track type to a BRA track type.
      #
      # type - The BAPS track type number.  Must NOT be Types::Track::NULL.
      #
      # Returns a symbol (:library, :file or :text) being the BRA equivalent of
      # the BAPS track type.
      def track_type_baps_to_bra(type)
        case type
        when Types::Track::LIBRARY
          :library
        when Types::Track::FILE
          :file
        when Types::Track::TEXT
          text
        else
          raise "Not a valid track type for conversion: #{type}"
        end
      end
    end
  end
end
