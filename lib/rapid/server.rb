require 'rapid/server/inspector'
require 'rapid/server/updater'

# This must be required after the above two.
require 'rapid/server/app'
require 'rapid/server/launcher'

module Rapid
  # The API server for the Rapid system
  #
  # The Sinatra app containing the server can be found as Rapid::Server::App.
  # Another class, Rapid::Server::Launcher, launches the App as a Rack process.
  module Server
  end
end
