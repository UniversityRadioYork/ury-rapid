require 'eventmachine'

require 'rapid/common/constants'
require 'rapid/model'
require 'rapid/server'
require 'kankri'

module Rapid
  # The main Rapid application
  #
  # This will usually be launched from bin/Rapid.
  class App
    def initialize(services, servers, model_view, reactor = nil)
      @services    = services
      @servers    = servers
      @model_view = model_view
      @reactor    = reactor || EventMachine
    end

    # Runs th Rapid application in a new EventMachine instance
    def run
      @model_view.log(:info, 'Now starting Rapid.')
      @model_view.log(:info, "Version: #{Rapid::Common::Constants::VERSION}.")

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
