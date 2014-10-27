require 'eventmachine'

require 'ury_rapid/common/constants'
require 'ury_rapid/model'
require 'ury_rapid/server'
require 'kankri'

module Rapid
  # The main Rapid application
  #
  # This will usually be launched from bin/Rapid.
  class App
    # Initialises the Rapid application
    #
    # @param root [Rapid::Services::Root]
    #   The root module.
    # @param reactor [Object]
    #   An object or class that may be used as an asynchronous IO reactor.
    def initialize(root, reactor = nil)
      @root    = root
      @reactor = reactor || EventMachine
    end

    # Runs the Rapid application in a new EventMachine instance
    def run
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
