require 'eventmachine'
require 'thin'
require 'yaml'
require 'active_support/core_ext/hash/keys'
require_relative 'server_app'
require_relative 'baps/client'
require_relative 'baps/commands'
require_relative 'baps/models'
require_relative 'models/creator'
require_relative 'baps/controller'

# Internal: Creates the dispatch for the reactor.
#
# web_app - The app to map to /.
#
# Returns the dispatch.
def make_dispatch(config, web_app)
  Rack::Builder.app do
    map(config[:server][:root]) { run(web_app) }
  end
end

# Internal: Starts the server.
#
# dispatch - The dispatch to use for the server.
# server   - The name of the server to start.
# host     - The hostname of the server.
# port     - The port on which the server will be started.
#
# Returns nothing.
def start_server(dispatch, server, host, port)
  Rack::Server.start({ app: dispatch, server: server, Host: host, Port: port })
end

# Internal: Makes sure the server supplied can run EventMachine.
#
# server - The name of the server to check.
#
# Returns nothing.
# Raises a string error if the server does not appear to be EM compatible.
def check_server_em_compatible(server)
  fail("Need an EM server, but #{server} isn't") unless em_compatible?(server)
end

# Internal: Decides whether the server supplied can run EventMachine.
#
# server - The name of the server to check.
#
# Returns true if the server is compatible, and false otherwise.
def em_compatible?(server)
  %w(thin hatetepe goliath).include?(server)
end

def run
  config = YAML.load_file('config.yml').deep_symbolize_keys!
  app, model, queue = make_dependencies(config)
  EM.run do
    setup_server(config, app)
    setup_client(config, model, queue)
  end
end

# Internal: Instantiates the dependencies for the BRA system.
#
# config - The configuration hash from which any settings should be read.
#
# Returns a list containing the Sinatra app, the model and the requests queue
# that should be used for making the client and server.
def make_dependencies(config)
  queue = EM::Queue.new

  model_config = config[:model]
  model_config.merge!(Bra::Baps::Commands.handlers(queue))

  model = Bra::Models::Creator.new(model_config).create
  Bra::Baps::Models.add_baps_models_to(model, config[:baps])

  app = Bra::ServerApp.new(config, model)
  [app, model, queue]
end

# Internal: Initialises the server end of BRA, which handles requests to and
# responses from the environment.
#
# config - The BRA configuration hash.
# opts   - Server options for Sinatra/Rack.
#
# Returns nothing.
def setup_server(config, app)
  server, host, port = config[:server].values_at(*%i(rack host port))

  dispatch = make_dispatch(config, app)

  check_server_em_compatible(server)

  start_server(dispatch, server, host, port)
end

# Internal: Initialises the client end of BRA, which handles requests to and
# responses from the BAPS server.
#
# config - The BRA configuration hash.
# model - The model that the client controls via BAPS responses.
#
# Returns nothing.
def setup_client(config, model, queue)
  client_config = config[:baps].values_at(*%i(host port username password))

  controller = Bra::Baps::Controller.new(model, queue)
  client = Bra::Baps::Client.new(queue, *client_config).start(controller)
end

run if __FILE__ == $PROGRAM_NAME
