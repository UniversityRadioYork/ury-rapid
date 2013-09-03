require 'eventmachine'
require 'thin'
require_relative 'bapsapiapp'

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
  # create a base-mapping that our application will set at. If I
  # have the following routes:
  #
  #   get '/hello' do
  #     'hello!'
  #   end
  #
  #   get '/goodbye' do
  #     'see ya later!'
  #   end
  #
  # Then I will get the following:
  #
  #   mapping: '/'
  #   routes:
  #     /hello
  #     /goodbye
  #
  #   mapping: '/api'
  #   routes:
  #     /api/hello
  #     /api/goodbye
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

def run(opts)
  # Start he reactor
  EM.run do
    server, host, port, web_app = get_options opts

    # create a base-mapping that our application will set at. If I
    # have the following routes:
    #
    #   get '/hello' do
    #     'hello!'
    #   end
    #
    #   get '/goodbye' do
    #     'see ya later!'
    #   end
    #
    # Then I will get the following:
    #
    #   mapping: '/'
    #   routes:
    #     /hello
    #     /goodbye
    #
    #   mapping: '/api'
    #   routes:
    #     /api/hello
    #     /api/goodbye
    dispatch = make_dispatch web_app
    check_server_em_compatible server
    start_server dispatch, server, host, port

  end
end

run app: BAPSApiApp.new
