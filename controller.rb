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
        playback_dump_functions,
        playlist_dump_functions,
        system_dump_functions
      ].reduce({}) { |a, e| a.merge! e }

      dispatch.register_response_handlers functions
    end

        # Public: Register playback response handler functions.
    #
    # Returns nothing.
    def playback_dump_functions
      {
        Responses::Playback::PLAYING => method(:playing),
        Responses::Playback::PAUSED => method(:paused),
        Responses::Playback::STOPPED => method(:stopped),
        Responses::Playback::POSITION => method(:position),
        Responses::Playback::CUE => method(:cue),
        Responses::Playback::INTRO => method(:intro),
        Responses::Playback::LOADED => method(:loaded)
      }
    end

    # Public: Register playlist response handler functions.
    #
    # Returns nothing.
    def playlist_dump_functions
      {
        Responses::Playlist::ITEM_DATA => method(:item_data),
        Responses::Playlist::ITEM_COUNT => method(:item_count),
      }
    end

    # Public: Register system response handler functions.
    #
    # Returns nothing.
    def system_dump_functions
      {
        Responses::System::CLIENT_ADD => method(:client_add),
        Responses::System::CLIENT_REMOVE => method(:client_remove)
      }
    end

    private

    def playing(response)
      @model.channel(response[:subcode]).state = :playing
    end

    def paused(response)
      @model.channel(response[:subcode]).state = :paused
    end

    def stopped(response)
      @model.channel(response[:subcode]).state = :stopped
    end

    def position(response)
      puts "[POSITION] Channel #{response[:subcode]} at #{response[:position]}"
    end

    def cue(response)
      puts "[CUE] Channel #{response[:subcode]} at #{response[:position]}"
    end

    def intro(response)
      puts "[INTRO] Channel #{response[:subcode]} at #{response[:position]}"
    end

    def item_data(response)
      id, index = response.values_at(*%i(subcode index))
      item_args = response.values_at(*%i(type title))
      item = Item.new(*item_args)

      @model.channel(id).add_item index, item
    end

    def loaded(response)
      puts "loaded #{response}"
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
  end
end
