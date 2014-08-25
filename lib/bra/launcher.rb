require 'colored'

require 'bra/app'
require 'bra/model/config'

module Bra
  # An object that builds the dependencies for a bra App and runs it
  class Launcher
    extend Forwardable

    def initialize(config, options = {})
      @drivers = {}
      @servers = {}

      @user_config = {}

      run_config(config)

      make_builders(options_with_defaults(options))

      @auth = make_auth(@user_config)
      @update_channel = make_channel
    end

    def run
      app.run
    end

    def self.launch(*args)
      new(*args).run
    end

    #
    # Configuration DSL
    #
    # This section of the Launcher code is intended to be used in configuration
    # files.
    #

    # Configures a driver and adds it to the launcher's state
    #
    # @api  public
    def driver(name, implementation_class, &block)
      @drivers[name] = [implementation_class, block]
    end

    # Configures a server and adds it to the launcher's state.
    #
    # @api  public
    def server(name, implementation_class, &block)
      @servers[name] = [implementation_class, block]
    end

    # Configures the model.
    #
    # @api  public
    def model(implementation_class, &block)
      @model_structure = implementation_class
      @model_config = block
    end

    # Configures a user and adds them to the user table.
    #
    # @api  public
    def user(name)
      @user_config[name] = yield
    end

    #
    # End configuration DSL
    #

    private

    DEFAULT_MODEL_STRUCTURE = 'bra/model/structures/standard'
    DEFAULT_DRIVER          = 'bra/baps/driver'

    # Runs the configuration passed to the Launcher
    #
    # This instance-evaluates the configuration, either as a Proc or as a
    # String.
    #
    # @api  private
    #
    # @param config [String|Proc]
    #   The String or Proc representing the configuration.
    #
    # @return [void]
    def run_config(config)
      instance_eval(&config) if config.is_a?(Proc)
      instance_eval(config) unless config.is_a?(Proc)
    end

    def make_builders(options)
      @app_maker                = options[:app]
      @auth_maker               = options[:auth]
      @channel_maker            = options[:channel]
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
      global_driver_view, global_server_view = mkmodel(logger)
      drivers = make_drivers(logger, global_driver_view)
      servers = make_servers(logger, global_server_view)
      [drivers, servers, global_driver_view]
    end

    #
    # Driver
    #

    def make_drivers(logger, model_view)
      @drivers.map do |name, (driver_class, driver_config)|
        driver_class.new(logger)
                    .tap { |d| d.instance_exec(&driver_config) }
                    .tap { |d| init_driver(name, model_view, d) }
      end
    end

    def init_driver(name, model_view, driver)
      sub_structure, register_driver_view = driver.sub_model(@update_channel)
      sub_model = sub_structure.create
      add_driver_model(model_view, name, sub_model)
      init_driver_model_view(sub_structure, sub_model, register_driver_view)
    end

    def init_driver_model_view(sub_structure, sub_model, register_driver_view)
      register_driver_view.call(make_driver_view(sub_model, sub_structure))
    end

    def add_driver_model(model_view, name, sub_model)
      model_view.post('', name, sub_model)
    end

    #
    # Model
    #

    def mkmodel(logger)
      structure = @model_structure.new(@update_channel, logger, @model_config)
      model = structure.create
      [make_driver_view(model, structure), make_server_view(model)]
    end

    def model_configurator(logger)
      make_model_configurator(
        @model_structure, make_channel, logger, @model_config
      )
    end

    #
    # Server
    #

    def make_servers(_logger, global_driver_view)
      @servers.map do |_name, (server_class, server_config)|
        server_class.new(global_driver_view, @auth).tap do |server|
          server.instance_eval(&server_config)
        end
      end
    end

    #
    # Default options
    #

    def options_with_defaults(options)
      options.reverse_merge(
        app:     Bra::App.method(:new),
        auth:    Kankri.method(:authenticator_from_hash),
        channel: Bra::Model::UpdateChannel.method(:new),
        logger:  method(:default_logger)
      ).reverse_merge(model_defaults)
    end

    def model_defaults
      {
        driver_view:        Bra::Model::DriverView.method(:new),
        model_configurator: Bra::Model::Config.method(:new),
        server_view:        Bra::Model::ServerView.method(:new)
      }
    end

    #
    # Default logger (TODO: move this elsewhere?)
    #

    def default_logger
      # TODO: Allow redirecting
      output = STDERR
      Logger.new(STDERR).tap do |logger|
        logger.formatter = proc do |severity, datetime, _progname, msg|
          [format_date(datetime, output),
           format_severity(severity, output),
           msg].join(' ') + "\n"
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

    #
    # Constructor delegators
    #

    def_delegator :@app_maker,                :call, :make_app
    def_delegator :@auth_maker,               :call, :make_auth
    def_delegator :@channel_maker,            :call, :make_channel
    def_delegator :@driver_view_maker,        :call, :make_driver_view
    def_delegator :@logger_maker,             :call, :make_logger
    def_delegator :@model_configurator_maker, :call, :make_model_configurator
    def_delegator :@model_structure_maker,    :call, :make_model_structure
    def_delegator :@server_view_maker,        :call, :make_server_view
  end
end
