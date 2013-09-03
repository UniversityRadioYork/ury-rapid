require_relative 'baps_client'
require_relative 'commands'
require_relative 'dispatch'
require_relative 'responses'

module Bra
  # Public: A testbed class for demonstrating how Bra's internal BAPS
  # connection works.
  class StateDumper
    # Public: Initialise a StateDumper.
    #
    # hostname - The host of the BAPS server to which StateDumper will connect.
    # port     - The port of the BAPS server to which StateDumper will connect.
    # username - The username with which the login will occur.
    # password - The password with which the login will occur.
    def initialize(hostname, port, username, password)
      client = BapsClient.new hostname, port
      reader = client.reader
      writer = client.writer
      response_source = Responses::Source.new(reader)
      @dispatch = Dispatch.new writer, response_source
      @username = username
      @password = password
    end

    # Public: Run the StateDumper.
    #
    # Returns nothing.
    def run
      login = Commands::Login.new(@username, @password)
      login.run(@dispatch) do |error_code, error_string|
        if error_code != Commands::Authenticate::Errors::OK
          p error_string
          @dispatch.stop
        else
          register_dump_functions
        end
      end

      @dispatch.pump_loop
    end

    private

    # Public: Register functions for dumping server state with the dispatch.
    #
    # Returns nothing.
    def register_dump_functions
      functions = [
        playback_dump_functions,
        playlist_dump_functions,
        system_dump_functions
      ].reduce({}) { |functions, batch| functions.merge! batch }

      @dispatch.register_response_handlers functions
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
        Responses::Playback::INTRO => method(:intro)
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

    def playing(response)
      puts "[PLAYING] Channel #{response[:subcode]} is playing"
    end

    def paused(response)
      puts "[PAUSED] Channel #{response[:subcode]} is paused"
    end

    def stopped(response)
      puts "[STOPPED] Channel #{response[:subcode]} is stopped"
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
      puts "[ITEM] Channel: #{response[:subcode]} Index: #{response[:index]}"
      puts "       Track: #{response[:name]} Type: #{response[:type]}"
    end

    def item_count(response)
      puts "[ITEM#] Channel: #{response[:subcode]} #{response[:count]} items"
    end

    def playing(response)
      puts "[PLAYING] Channel #{response[:subcode]} is playing"
    end

    def paused(response)
      puts "[PAUSED] Channel #{response[:subcode]} is paused"
    end

    def stopped(response)
      puts "[STOPPED] Channel #{response[:subcode]} is stopped"
    end

    def client_add(response)
      puts "[CLIENTCHANGE] Client #{response[:client]} appeared"
    end

    def client_remove(response)
      puts "[CLIENTCHANGE] Client #{response[:client]} disappeared"
    end
  end
end

Bra::StateDumper.new(*ARGV).run if __FILE__ == $PROGRAM_NAME
