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
    def initialize(services, servers, model_view, reactor = nil)
      @services    = services
      @servers    = servers
      @model_view = model_view
      @reactor    = reactor || EventMachine
    end

    # Runs th bra application in a new EventMachine instance
    def run
      @model_view.log(:info, 'Now starting bra.')
      @model_view.log(:info, "Version: #{Bra::Common::Constants::VERSION}.")

      @reactor.run do
        @servers.each(&:run)
        @services.each(&:run)

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
