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

    # Public: Register functions for dumping server state with the dispatch.
    #
    # Returns nothing.
    def register_dump_functions
      @dispatch.register(Responses::Playlist::ITEM_DATA) do |response, _|
        puts "[ITEM] Channel: #{response[:subcode]} Index: #{response[:index]}"
        puts "       Track: #{response[:name]} Type: #{response[:type]}"
      end
      @dispatch.register(Responses::Playlist::ITEM_COUNT) do |response, _|
        puts "[ITEM#] Channel: #{response[:subcode]} #{response[:count]} items"
      end
    end
  end
end

Bra::StateDumper.new(*ARGV).run if __FILE__ == $PROGRAM_NAME
