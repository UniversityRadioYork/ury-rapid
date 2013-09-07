require_relative 'baps_codes'

module Bra
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
        BapsCodes::Playback::PLAY => method(:playing),
        BapsCodes::Playback::PAUSE => method(:paused),
        BapsCodes::Playback::STOP => method(:stopped),
        BapsCodes::Playback::POSITION => method(:position),
        BapsCodes::Playback::CUE => method(:cue),
        BapsCodes::Playback::INTRO => method(:intro),
        BapsCodes::Playback::LOADED => method(:loaded)
      }
    end

    # Public: Register playlist response handler functions.
    #
    # Returns nothing.
    def playlist_functions
      {
        BapsCodes::Playlist::ITEM_DATA => method(:item_data),
        BapsCodes::Playlist::ITEM_COUNT => method(:item_count),
        BapsCodes::Playlist::RESET => method(:reset)
      }
    end

    # Public: Register system response handler functions.
    #
    # Returns nothing.
    def system_functions
      {
        BapsCodes::System::CLIENT_ADD => method(:client_add),
        BapsCodes::System::CLIENT_REMOVE => method(:client_remove)
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
      item_args = response.values_at(:type, :title)
      item = Item.new(*item_args)

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
      if response[:title] == '--LOADING--'
        [:loading, nil]
      elsif response[:title] == '--LOAD FAILED--'
        [:failed, nil]
      else
        item_args = response.values_at(:type, :title)
        position response if response.key? :position
        [:ok, Item.new(*item_args)]
      end
    end
  end
end
