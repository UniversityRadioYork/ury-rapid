require 'bra/server/inspector'
require 'bra/server/updater'

# This must be required after the above two.
require 'bra/server/app'
require 'bra/server/launcher'

module Bra
  # The API server for the bra system
  #
  # The Sinatra app containing the server can be found as Bra::Server::App.
  # Another class, Bra::Server::Launcher, launches the App as a Rack process.
  module Server
  end
end
