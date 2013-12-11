require 'eventmachine'
require 'thin'
require 'yaml'
require 'active_support/core_ext/hash/keys'
require_relative 'server/launcher'
require_relative 'models/creator'
require_relative 'common/config_authenticator'

CONFIG_FILE = 'config.yml'

# Runs bra (this is the main function)
def run
  config = load_config
  app = App.new(config)
  EventMachine.run { app.run }
end

# Loads the bra configuration.
def load_config
  YAML.load_file(CONFIG_FILE).deep_symbolize_keys!
end

class App
  def initialize(config)
    @driver = init_driver(config[:driver])
    @model = init_model(config[:model], @driver)
    @server = init_server(config[:server], @model)
  end

  def run
    @server.run
    @driver.run(@model)
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
    # and to add in driver-specific configuration, like model handlers.
    full_config = driver.configure_model(init_config)

    # Now we create the driver-neutral model, but the driver might want to add
    # its own model items into the model space, so we pass the model back to
    # the driver to post-process.
    creator = Bra::Models::Creator.new(full_config)
    driver.process_model(creator.create)
  end

  # Creates the authenticator for the server
  def authenticator(config)
    Bra::Common::ConfigAuthenticator.new(config[:users])
  end
end

run if __FILE__ == $PROGRAM_NAME
