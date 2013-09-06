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
        BapsCodes::Playback::PLAYING => method(:playing),
        BapsCodes::Playback::PAUSED => method(:paused),
        BapsCodes::Playback::STOPPED => method(:stopped),
        BapsCodes::Playback::POSITION => method(:position),
        BapsCodes::Playback::CUE => method(:cue),
        BapsCodes::Playback::INTRO => method(:intro),
        BapsCodes::Playback::LOADED => method(:loaded)
      }
    end

    # Public: Register playlist response handler functions.
    #
    # Returns nothing.
    def playlist_dump_functions
      {
        BapsCodes::Playlist::ITEM_DATA => method(:item_data),
        BapsCodes::Playlist::ITEM_COUNT => method(:item_count),
      }
    end

    # Public: Register system response handler functions.
    #
    # Returns nothing.
    def system_dump_functions
      {
        BapsCodes::System::CLIENT_ADD => method(:client_add),
        BapsCodes::System::CLIENT_REMOVE => method(:client_remove)
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
      @model.channel(response[:subcode]).position = response[:position]
    end

    def cue(response)
      @model.channel(response[:subcode]).cue = response[:position]
      puts "[CUE] Channel #{response[:subcode]} at #{response[:position]}"
    end

    def intro(response)
      @model.channel(response[:subcode]).intro = response[:position]
    end

    def item_data(response)
      id, index = response.values_at(:subcode, :index)
      item_args = response.values_at(:type, :title)
      item = Item.new(*item_args)

      @model.channel(id).add_item index, item
    end

    def loaded(response)
      @model.channel(response[:subcode]).loaded = loaded_item response
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

    # Converts an loaded response into an Item or symbol.
    #
    # response - The loaded response to convert.
    #
    # Returns an Item or a symbol (:loading or :load_failed).
    def loaded_item(response)
      if response[:title] == '--LOADING--'
        :loading
      elsif response[:title] == '--LOAD FAILED--'
        :failed
      else
        item_args = response.values_at(:type, :title)
        position response if response.key? :position
        Item.new(*item_args)
      end
    end
  end
end
