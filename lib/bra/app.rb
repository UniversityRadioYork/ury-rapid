require 'active_support/core_ext/hash/keys'
require 'eventmachine'
require 'thin'
require 'yaml'

require 'bra/common/config_authenticator'
require 'bra/common/constants'
require 'bra/model/creator'
require 'bra/server/launcher'

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
    def init_model(init_config, driver)
      # Make an updates channel here, because it's neither the driver's
      # responsibility, nor can it easily be made in the YAML.
      init_config[:update_channel] = EventMachine::Channel.new

      # The model config is created by loading up driver-neutral configuration
      # from the central YAML file, then passing it to the driver to check for
      # unsound config (like requesting 3 channels on a single-channel playout)
      # and to add in driver-specific configuration, like model handlers or
      # model extension creators.
      full_config = driver.configure_model(init_config)

      make_model_with(full_config)
    end

    # Given a full model configuration, builds the model from a structure class
    def make_model_with(full_config)
      structure_module = full_config[:source]
      require structure_module

      structure = Structure.new(full_config)
      model = structure.create
      extend_model(full_config, model)
    end

    # Apply any extensions in the model config to the model.
    def extend_model(full_config, model)
      full_config[:extensions].try do |extensions|
        # TODO: Handle strings and other un-instantiated models.
        extensions.each { |extension| extension.extend(model) }
      end

      model
    end

    # Creates the authenticator for the server
    def authenticator(config)
      Bra::Common::ConfigAuthenticator.new(config[:users])
    end
  end
end
