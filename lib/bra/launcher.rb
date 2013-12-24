require 'bra/app'
require 'bra/model/config'

module Bra
  # An object that builds the dependencies for a bra App and runs it
  class Launcher
    extend Forwardable

    def initialize(config, options = {})
      split_config(config)
      make_builders(options_with_defaults(options))
    end

    def run
      app.run
    end

    def self.launch(*args)
      new(*args).run
    end

    private

    DEFAULT_MODEL_STRUCTURE = 'bra/model/structures/standard'
    DEFAULT_DRIVER          = 'bra/baps/driver'

    def split_config(config)
      @driver_config = config[:driver]
      @server_config = config[:server]
      @model_config  = config[:model]
      @user_config   = config[:users]
    end

    def make_builders(options)
      @app_maker                = options[:app]
      @auth_maker               = options[:auth]
      @channel_maker            = options[:channel]
      @driver_maker             = options[:driver]
      @model_configurator_maker = options[:model_configurator]
      @model_structure_maker    = options[:model_structure]
      @server_maker             = options[:server]
    end

    def app
      make_app(*app_arguments)
    end

    def app_arguments
      new_driver = driver
      new_model  = model(new_driver)
      new_server = server(new_model)
      [new_driver, new_model, new_server]
    end

    #
    # Driver
    #

    def driver
      make_driver(@driver_config)
    end

    #
    # Model
    #

    def model(driver)
      model_configurator.configure_with(driver).make
    end

    def model_configurator
      make_model_configurator(model_structure, make_channel, @model_config)
    end

    def model_structure
      make_model_structure(@model_config)
    end

    #
    # Server
    #

    def server(new_model)
      make_server(@server_config, new_model, auth)
    end

    def auth
      make_auth(@user_config)
    end

    #
    # Default options
    #

    def options_with_defaults(options)
      options.reverse_merge(
        app:                Bra::App.method(:new),
        auth:               Kankri.method(:authenticator_from_hash),
        channel:            EventMachine::Channel.method(:new),
        driver:             method(:driver_from_config),
        model_configurator: Bra::Model::Config.method(:new),
        model_structure:    method(:structure_from_config),
        server:             Bra::Server::Launcher.method(:new)
      )
    end

    #
    # External module includers
    #

    def driver_from_config
      driver_module = @driver_config[:source] || DEFAULT_DRIVER
      require driver_module

      Driver.new(@driver_config)
    end

    def structure_from_config
      structure_module = @structure_module[:source] || DEFAULT_MODEL_STRUCTURE
      require structure_module

      Structure
    end

    #
    # Constructor delegators
    #

    def_delegator :@app_maker,                :call, :make_app
    def_delegator :@auth_maker,               :call, :make_auth
    def_delegator :@channel_maker,            :call, :make_channel
    def_delegator :@driver_maker,             :call, :make_driver
    def_delegator :@model_configurator_maker, :call, :make_model_configurator
    def_delegator :@model_structure_maker,    :call, :make_model_structure
    def_delegator :@server_maker,             :call, :make_server
  end
end
