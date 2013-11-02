require 'eventmachine'
require_relative 'client'
require_relative 'commands'
require_relative 'controller'
require_relative 'models'

##
# The top-level driver interface for the BAPS BRA driver.
class Driver
  ##
  # Initialise the driver given its driver configuration.
  def initialize(config)
    # We'll need this config later when we're post-processing the model.
    @config = config

    # We need a queue for requests to the BAPS server to be funneled
    # through.  This will later need to be given to the actual BAPS client
    # to read from, and also to the model hooks to write to.
    @queue = EventMachine::Queue.new

    # Most of the actual low-level BAPS poking is contained inside this
    # client object, which is what hooks into the BRA EventMachine
    # instance.  We need to give it access to parts of the driver config so
    # it knows where and how to connect to BAPS.
    client_config = config.values_at(*%i(host port username password))
    @client = Bra::Baps::Client.new(@queue, *client_config)
  end 

  ##
  # Given the initial model configuration, prepare it with driver-specific
  # configuration ready for the model initialisation.
  # 
  # This returns its changes, but may or may not mutate the original
  # model_config.
  def configure_model(model_config)
    # Add in the BAPS-specific model handlers, so that model actions
    # trigger BAPS commands.
    #
    # The handlers all send commands to the server, so we need to give them
    # access to the queue here.
    model_config.merge!(Bra::Baps::Commands.handlers(@queue))
  end

  ##
  # Perform post-processing on the finished BRA model root.
  # 
  # This returns its changes, but may or may not mutate the original model.
  #
  def process_model(model)
    # The BAPS driver exposes some of its configuration as part of the BRA
    # model, so we need to extend the model to accommodate these.
    Bra::Baps::Models.add_baps_models_to(model, @config)
  end

  ##
  # Begin running the driver, given the completed BRA model.
  # 
  # This function is always run within an EventMachine run block.
  def run(model)
    # The controller receives responses from the BAPS server via the client
    # and reacts on them, either updating the model or sending replies to
    # the request queue.  
    # 
    # We'd make the controller earlier, but we need access to the model,
    # which we only get definitive access to here.
    controller = Bra::Baps::Controller.new(model, @queue)

    # Now we can run the client, passing it the controller so it can send
    # BAPS responses to it.  The client will get BAPS requests sent to it
    # via the queue, thus completing the communication paths.
    @client.run(controller)
  end
end
