require 'eventmachine'
require 'thin'
require 'yaml'
require_relative 'bapsapiapp'
require_relative 'baps_client'
require_relative 'model'
require_relative 'controller'

# This example shows you how to embed Sinatra into your EventMachine
# application. This is very useful if you're application needs some
# sort of API interface and you don't want to use EM's provided
# web-server.

# Internal: Unpack the options from the options hash.
#
# opts - A hash with keys :server, :host, :port and :app.
#        The first three are optional and will be filled in with defaults.
#
# Returns a list [server, host, port, app].
def get_options(opts)
  # define some defaults for our app
  server  = opts[:server] || 'thin'
  host    = opts[:host]   || '0.0.0.0'
  port    = opts[:port]   || '8181'
  web_app = opts[:app]
  [server, host, port, web_app]
end

# Internal: Creates the dispatch for the reactor.
#
# web_app - The app to map to /.
#
# Returns the dispatch.
def make_dispatch(web_app)
  Rack::Builder.app do
    map '/' do
      run web_app
    end
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
  Rack::Server.start({
    app:    dispatch,
    server: server,
    Host:   host,
    Port:   port
  })
end

# Internal: Makes sure the server supplied can run EventMachine.
#
# server - The name of the server to check.
#
# Returns nothing.
# Raises a string error if the server does not appear to be EM compatible.
def check_server_em_compatible(server)
  unless %W{thin hatetepe goliath}.include? server
    raise "Need an EM webserver, but #{server} isn't"
  end
end

def run
  config = YAML.load_file 'config.yml'
  model = Bra::Model.new
  queue = EM::Queue.new
  app = BAPSApiApp.new config, model, queue

  EM.run do
    setup_server config, app
    setup_client config, model, queue
  end
end

# Internal: Initialises the server end of BRA, which handles requests to and
# responses from the environment.
#
# config - The BRA configuration hash.
# opts   - Server options for Sinatra/Rack.
#
# Returns nothing.
def setup_server(config, app)
  server, host, port = get_options config

  dispatch = make_dispatch app

  check_server_em_compatible server

  start_server dispatch, server, host, port
end

# Internal: Initialises the client end of BRA, which handles requests to and
# responses from the BAPS server.
#
# config - The BRA configuration hash.
# model - The model that the client controls via BAPS responses.
#
# Returns nothing.
def setup_client(config, model, queue)
  client_config = config.values_at(*%W(hostname port username password))

  client = Bra::BapsClient.new(queue, *client_config)
  client.start do |dispatch, _|
    controller = Bra::Controller.new model
    controller.register dispatch
  end
end

run if __FILE__ == $PROGRAM_NAME
