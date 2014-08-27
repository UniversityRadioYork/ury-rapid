require 'ury-rapid/server/inspector'
require 'ury-rapid/server/updater'

# This must be required after the above two.
require 'ury-rapid/server/app'
require 'ury-rapid/server/launcher'

module Rapid
  # The API server for the Rapid system
  #
  # The Sinatra app containing the server can be found as Rapid::Server::App.
  # Another class, Rapid::Server::Launcher, launches the App as a Rack process.
  module Server
  end
end
