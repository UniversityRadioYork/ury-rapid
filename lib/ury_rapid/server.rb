require 'ury_rapid/server/inspector'
require 'ury_rapid/server/updater'
require 'ury_rapid/server/auth_request'

# This must be required after the above.
require 'ury_rapid/server/app'
require 'ury_rapid/server/service'

module Rapid
  # The API server for the Rapid system
  #
  # The Sinatra app containing the server can be found as Rapid::Server::App.
  # Another class, Rapid::Server::Service, launches the App as a Rack process.
  module Server
  end
end
