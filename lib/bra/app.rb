require 'eventmachine'
require 'thin'
require 'yaml'

require 'bra/common/constants'
require 'bra/model'
require 'bra/server'
require 'kankri'

module Bra
  # The main bra application
  #
  # This will usually be launched from bin/bra.
  class App
    def initialize(driver, model, server, reactor = nil)
      @driver  = driver
      @model   = model
      @server  = server
      @reactor = reactor || EventMachine
    end

    # Runs th bra application in a new EventMachine instance
    def run
      @reactor.run do
        @server.run(Bra::Model::ServerView.new(@model))
        @driver.run(Bra::Model::DriverView.new(@model))
        Signal.trap("INT") { EventMachine.stop }
        Signal.trap("TERM") { EventMachine.stop }
      end
    end
  end
end
