require 'eventmachine'

require 'ury-rapid/common/constants'
require 'ury-rapid/model'
require 'ury-rapid/server'
require 'kankri'

module Rapid
  # The main Rapid application
  #
  # This will usually be launched from bin/Rapid.
  class App
    # Initialises the Rapid application
    #
    # @param modules [Rapid::Modules::Set]
    #   The set of modules.  Enabled modules will be run by the app.
    # @param model_view [ServiceView]
    #   A service view of the entire model.
    def initialize(modules, model_view, reactor = nil)
      @modules   = modules
      @model_view = model_view
      @reactor    = reactor || EventMachine
    end

    # Runs the Rapid application in a new EventMachine instance
    def run
      @model_view.log(:info, 'Now starting Rapid.')
      @model_view.log(:info, "Version: #{Rapid::Common::Constants::VERSION}.")

      @reactor.run do
        @modules.run

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
