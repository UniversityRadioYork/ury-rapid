require 'colored'

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
      @server_maker             = options[:server]
      @logger_maker             = options[:logger]
      make_model_builders(options)
    end

    def make_model_builders(options)
      @driver_view_maker        = options[:driver_view]
      @model_configurator_maker = options[:model_configurator]
      @model_structure_maker    = options[:model_structure]
      @server_view_maker        = options[:server_view]
    end

    def app
      make_app(*app_arguments)
    end

    def app_arguments
      logger = make_logger
      new_driver = driver(logger)
      new_driver_view, new_server_view = model(logger, new_driver)
      new_server = server
      [new_driver, new_driver_view, new_server, new_server_view]
    end

    #
    # Driver
    #

    def driver(logger)
      make_driver(@driver_config, logger)
    end

    #
    # Model
    #

    def model(logger, driver)
      config = model_configurator(logger).configure_with(driver)
      model = config.make
      [make_driver_view(config, model), make_server_view(model)]
    end

    def model_configurator(logger)
      make_model_configurator(
        model_structure, make_channel, logger, @model_config
      )
    end

    def model_structure
      make_model_structure(@model_config)
    end

    #
    # Server
    #

    def server
      make_server(@server_config, auth)
    end

    def auth
      make_auth(@user_config)
    end

    #
    # Default options
    #

    def options_with_defaults(options)
      options.reverse_merge(
        app:     Bra::App.method(:new),
        auth:    Kankri.method(:authenticator_from_hash),
        channel: Bra::Model::UpdateChannel.method(:new),
        driver:  method(:driver_from_config),
        logger:  method(:default_logger),
        server:  Bra::Server::Launcher.method(:new)
      ).reverse_merge(model_defaults)
    end

    def model_defaults
      {
        driver_view:        Bra::Model::DriverView.method(:new),
        model_configurator: Bra::Model::Config.method(:new),
        server_view:        Bra::Model::ServerView.method(:new),
        model_structure:    method(:structure_from_config)
      }
    end

    #
    # Default logger (TODO: move this elsewhere?)
    #

    def default_logger
      # TODO: Allow redirecting
      output = STDERR
      Logger.new(STDERR).tap do |logger|
        logger.formatter = proc do |severity, datetime, progname, msg|
          [ format_date(datetime, output),
            format_severity(severity, output),
            msg
          ].join(' ') + "\n"
        end
      end
    end

    # Colourises the severity if the logging output is a terminal
    def format_severity(severity, output)
      "[#{output.is_a?(String) ? severity : coloured_severity(severity)}]"
    end

    def format_date(datetime, output)
      dt = datetime.strftime('%d/%m/%y %H:%M:%S')
      output.is_a?(String) ? dt : dt.green
    end

    SEVERITIES = {
      'DEBUG' => :green,
      'INFO' => :blue,
      'WARN' => :yellow,
      'ERROR' => :red,
      'FATAL' => :magenta
    }

    def coloured_severity(severity)
      severity.send(SEVERITIES.fetch(severity, :white))
    end

    #
    # External module includers
    #

    def driver_from_config(driver_config, logger)
      driver_module = driver_config[:source] || DEFAULT_DRIVER
      require driver_module

      Driver.new(driver_config, logger)
    end

    def structure_from_config(structure_config)
      structure_module = structure_config[:source] || DEFAULT_MODEL_STRUCTURE
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
    def_delegator :@driver_view_maker,        :call, :make_driver_view
    def_delegator :@logger_maker,             :call, :make_logger
    def_delegator :@model_configurator_maker, :call, :make_model_configurator
    def_delegator :@model_structure_maker,    :call, :make_model_structure
    def_delegator :@server_maker,             :call, :make_server
    def_delegator :@server_view_maker,        :call, :make_server_view
  end
end
