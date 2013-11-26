require 'eventmachine'
require 'thin'
require 'yaml'
require 'active_support/core_ext/hash/keys'
require_relative 'server_app'
require_relative 'models/creator'
require_relative 'common/config_authenticator'

# Internal: Creates the dispatch for the reactor.
#
# web_app - The app to map to /.
#
# Returns the dispatch.
def make_dispatch(config, web_app)
  Rack::Builder.app do
    map(config[:root]) { run(web_app) }
  end
end

# Internal: Starts the server.
#
# dispatch - The dispatch to use for the server.
# server   - The name of the server to start.
# host     - The hostname of the server.
# port     - The port on which the server will be started.
#
# @return [void]
def start_server(dispatch, server, host, port)
  Rack::Server.start({ app: dispatch, server: server, Host: host, Port: port })
end

# Makes sure the server supplied can run EventMachine
#
# server - The name of the server to check.
#
# @return [void]
# Raises a string error if the server does not appear to be EM compatible.
def check_server_em_compatible(server)
  fail("Need an EM server, but #{server} isn't") unless em_compatible?(server)
end

# Decides whether the server supplied can run EventMachine
#
# server - The name of the server to check.
#
# Returns true if the server is compatible, and false otherwise.
def em_compatible?(server)
  %w(thin hatetepe goliath).include?(server)
end

# Runs bra (this is the main function)
def run
  config = YAML.load_file('config.yml').deep_symbolize_keys!

  driver = init_driver(config[:driver])
  model = init_model(config[:model], driver)
  app = Bra::ServerApp.new(
    config[:server], model,
    Bra::Common::ConfigAuthenticator.new(config[:server][:users])
  )

  EventMachine.run do
    setup_server(config[:server], app)
    driver.run(model)
  end
end

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

# Create a model from its config and the playout system driver.
def init_model(init_config, driver)
  # The model config is created by loading up driver-neutral configuration from
  # the central YAML file, then passing it to the driver to check for
  # unsound config (like requesting 3 channels on a single-channel playout) and
  # to add in driver-specific configuration, like model handlers.
  full_config = driver.configure_model(init_config)

  # Now we create the driver-neutral model, but the driver might want to add
  # its own model items into the model space, so we pass the model back to the
  # driver to post-process.
  creator = Bra::Models::Creator.new(full_config)
  driver.process_model(creator.create)
end

# Initialises the server end of bra
#
# This handles requests to and responses from the environment.
#
# @param config [Hash] The bra server configuration.
# @param app [ServerApp] The server application.
#
# @return [void]
def setup_server(config, app)
  server, host, port = config.values_at(*%i(rack host port))

  dispatch = make_dispatch(config, app)

  check_server_em_compatible(server)

  start_server(dispatch, server, host, port)
end

run if __FILE__ == $PROGRAM_NAME
