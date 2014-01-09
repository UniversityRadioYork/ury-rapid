require 'eventmachine'

require 'bra/common/constants'
require 'bra/model'
require 'bra/server'
require 'kankri'

module Bra
  # The main bra application
  #
  # This will usually be launched from bin/bra.
  class App
    def initialize(driver, driver_view, server, server_view, reactor = nil)
      @driver      = driver
      @driver_view = driver_view
      @server      = server
      @server_view = server_view
      @reactor     = reactor || EventMachine
    end

    # Runs th bra application in a new EventMachine instance
    def run
      @driver_view.log(:info, 'Now starting bra.')
      @driver_view.log(:info, "Version: #{Bra::Common::Constants::VERSION}.")

      @reactor.run do
        @server.run(@server_view)
        @driver.run(@driver_view)

        Signal.trap('INT', &method(:close))
        Signal.trap('TERM', &method(:close))
      end
    end

    def close(signal)
      puts "Caught signal #{signal} -- exiting"
      EventMachine.stop
    end
  end
end
