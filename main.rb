require_relative "baps_client"
require_relative "commands"
require_relative "dispatch"
require_relative "responses"
require "digest"

if __FILE__ == $0
  hostname, port, username, password = ARGV
  client = BapsClient.new hostname, port

  reader = client.reader
  writer = client.writer
  response_source = Responses::Source.new(reader)

  welcome_message = reader.string
  puts welcome_message

  dispatch = Dispatch.new writer, response_source
  login = Commands::Login.new(username, password)
  login.run(dispatch) do |error_code, error_string|
    if error_code != Commands::Authenticate::Errors::OK
      p error_string
      dispatch.stop
    else
      dispatch.register(Responses::Playlist::ITEM_DATA) do |response, _|
        puts "[ITEM] Channel: #{response[:subcode]} Index: #{response[:index]}"
        puts "       Track: #{response[:name]} Type: #{response[:type]}"
      end
      dispatch.register(Responses::Playlist::ITEM_COUNT) do |response, _|
        puts "[ITEM#] Channel: #{response[:subcode]} #{response[:count]} items"
      end
    end
  end

  dispatch.pump_loop
end
