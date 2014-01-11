require 'eventmachine'

require 'bra/baps/client'
require 'bra/baps/models'
require 'bra/baps/requests/requester'
require 'bra/baps/responses/responder'

# The top-level driver interface for the BAPS BRA driver
class Driver
  extend Forwardable

  # Initialise the driver given its driver configuration
  #
  # @param config [Hash]  The configuration hash for the driver.
  # @param logger [Object]  An object that can be used to log messages from
  #   the driver.
  def initialize(config, logger)
    # We'll need this config later when we're post-processing the model.
    @config = config

    @logger = logger
    log_initialisation

    # We need a queue for requests to the BAPS server to be funneled
    # through.  This will later need to be given to the actual BAPS client
    # to read from, and also to the requester to write to.
    # This doesn't need to be an instance variable, as it is taken up by
    # @requester and @client.
    queue = EventMachine::Queue.new

    # The requester contains all the logic for instructing BAPS to make model
    # changes happen.
    @requester = Bra::Baps::Requests::Requester.new(queue, @logger)

    # Most of the actual low-level BAPS poking is contained inside this
    # client object, which is what hooks into the BRA EventMachine
    # instance.  We need to give it access to parts of the driver config so
    # it knows where and how to connect to BAPS.
    client_config = config.values_at(*%i(host port username password))
    @client = Bra::Baps::Client.new(queue, logger, *client_config)
  end

  # Prepare model configuration with driver specifics ready for initialisation
  #
  # This returns its changes, but may or may not mutate the original
  # model_config.
  #
  # @return [Config] The prepared configuration.
  def configure_model(config)
    # Add in the BAPS-specific model handlers, so that model actions
    # trigger BAPS commands.
    extend_model(config)
    add_handlers(config)
  end

  # Begin running the driver, given a view of the completed model
  #
  # This function is always run within an EventMachine run block.
  #
  # @param model_view [DriverModelView]  The driver's view of the model.
  def run(model_view)
    # The responder receives responses from the BAPS server via the client
    # and reacts on them, either updating the model or asking the requester to
    # intervene.
    #
    # We'd make the responder earlier, but we need access to the model,
    # which we only get definitive access to here.
    responder = Bra::Baps::Responses::Responder.new(model_view, @requester)

    # Now we can run the client, passing it the responder so it can send
    # BAPS responses to it.  The client will get BAPS requests sent to it
    # via the queue, thus completing the communication paths.
    @client.run(responder)

    # Finally, get the ball rolling by asking the requester to initiate log-in.
    # This sets up a chain reaction between the requester and responder that
    # brings up the server connection.
    @requester.login_initiate
  end

  private

  def_delegator :@requester, :add_handlers

  def log_initialisation
    @logger.info('Initialising BAPS driver...')
    @logger.info("BAPS server: #{@config[:host]}:#{@config[:port]}")
  end

  def extend_model(model_config)
    model_config.add_extension(create_extender(model_config))
  end

  def create_extender(model_config)
    Bra::Baps::Model::Creator.new(model_config, @config)
  end
end
