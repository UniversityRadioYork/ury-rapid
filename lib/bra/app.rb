require 'active_support/core_ext/hash/keys'
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
    def initialize(config)
      @driver = init_driver(config[:driver])
      @model = init_model(config[:model], @driver)
      @server = init_server(config[:server], @model)
    end

    # Creates a new App with the config in the given YAML file
    def self.from_config_file(file = nil)
      file ||= Bra::Common::Constants::CONFIG_FILE
      new(YAML.load_file(file).deep_symbolize_keys!)
    end

    # Runs th bra application in a new EventMachine instance
    def run
      EventMachine.run do
        @server.run
        @driver.run(@model)
        Signal.trap("INT") { EventMachine.stop }
        Signal.trap("TERM") { EventMachine.stop }
      end
    end

    private

    # Find the correct driver from the config, and initialise it
    #
    # The driver is the part of the bra system that interfaces with the playout
    # system.  It runs in bra's EventMachine instance and is wired into the bra
    # model.
    def init_driver(config)
      driver_module = config[:source]
      require driver_module

      Driver.new(config)
    end

    def init_server(config, model)
      Bra::Server::Launcher.new(config, model, authenticator(config))
    end

    # Create a model from its config and the playout system driver.
    # The model config is created by loading up driver-neutral configuration
    # from the central YAML file, then passing it to the driver to check for
    # unsound config (like requesting 3 channels on a single-channel playout)
    # and to add in driver-specific configuration, like model handlers or
    # model extension creators.
    def init_model(options, driver)
      make_initial_model(options).configure_with(driver).make
    end

    def make_initial_model(options)
      Bra::Model::Config.new(make_channel, options)
    end

    # Make an updates channel here, because it's neither the driver's
    # responsibility, nor can it easily be made in the YAML.
    def make_channel
      EventMachine::Channel.new
    end

    # Creates the authenticator for the server
    def authenticator(config)
      Kankri::authenticator_from_hash(config[:users])
    end
  end
end
