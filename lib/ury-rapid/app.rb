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
    # @param root [Rapid::Modules::Root]
    #   The root module.
    # @param reactor [Object]
    #   An object or class that may be used as an asynchronous IO reactor.
    def initialize(root, reactor = nil)
      @root    = root
      @reactor = reactor || EventMachine
    end

    # Runs the Rapid application in a new EventMachine instance
    def run
      @root.log(:info, 'Now starting Rapid.')
      @root.log(:info, "Version: #{Rapid::Common::Constants::VERSION}.")

      @reactor.run do
        @root.run

        Signal.trap('INT', &method(:close))
        Signal.trap('TERM', &method(:close))
      end
    end

    def close(signal)
      $stderr.puts("Caught signal #{signal} -- exiting.")
      EventMachine.stop
    end
  end
end
