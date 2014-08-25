require 'colored'

require 'bra/app'
require 'bra/model/config'

module Bra
  # An object that builds the dependencies for a bra App and runs it
  class Launcher
    extend Forwardable

    def initialize(config, options = {})
      @drivers = ModuleSet.new()
      @servers = ModuleSet.new()

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

    ## Drivers ##

    # Configures a driver
    #
    # This does not enable the driver; use #enable_driver.
    #
    # @api  public
    def_delegator :@drivers, :configure, :driver

    # Enables a driver at launch-time
    #
    # The driver must have been previously configured, with #driver.
    #
    # @api      public
    # @example  Enables the driver 'production' at launch time.
    #   # In config.rb
    #   enable_driver :production
    #
    # @return [void]
    def_delegator :@drivers, :enable, :enable_driver

    ## Servers ##

    # Configures a server
    #
    # @api  public
    def_delegator :@servers, :configure, :server

    # Enables a server at launch-time
    #
    # The server must have been previously configured, with #server.
    #
    # @api      public
    # @example  Enables the server 'http' at launch time.
    #   # In config.rb
    #   enable_server :http
    #
    # @return [void]
    def_delegator :@servers, :enable, :enable_server

    ## Models ##

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

    # Initialises all drivers that are enabled at launch-time
    #
    # See #driver and #enable_driver in the configuration DSL.
    def make_drivers(logger, model_view)
      @drivers.constructor_arguments = [logger]
      @drivers.module_create_hook =
        ->(name, d) { init_driver(name, model_view, d) }
      @drivers.start_enabled
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

    # Initialises all server that are enabled at launch-time
    #
    # See #server and #enable_server in the configuration DSL.
    def make_servers(_logger, global_driver_view)
      @servers.constructor_arguments = [global_driver_view, @auth]
      @servers.start_enabled
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

  # A set of BRA modules
  #
  # A ModuleSet holds a set of configured BRA modules (drivers or servers), as
  # well as information about which modules are enabled at launch-time.
  class ModuleSet
    # Initialises a ModuleSet
    #
    # The ModuleSet, by default, passes nothing to module constructors, and
    # does nothing with the modules after construction.  Use
    # #constructor_arguments= and #module_create_hook= to override this.
    #
    # @api      semipublic
    # @example  Create a new ModuleSet
    #   ms = ModuleSet.new
    def initialize
      @modules = {}
      @enabled_modules = []
      @constructor_arguments = []
      @module_create_hook = ->(*) {}
    end

    # Adds a module and its configuration to the ModuleSet
    #
    # @api      semipublic
    # @example  Configure a module
    #   ms.configure(:a_module_name, Module::Class::Here) do
    #     # Module DSL goes here
    #   end
    #
    # @param name [Symbol]
    #   The name to give to this module instance.
    #
    # @param implementation_class [Class]
    #   The module class.
    #
    # @return [void]
    def configure(name, implementation_class, &block)
      @modules[name] = [implementation_class, block]
    end

    # Enables a configured module at load-time
    #
    # @api      semipublic
    # @example  Enable a module
    #   ms.enable(:a_module_name)
    #
    # @param name [Symbol]
    #   The name of the module to enable at load-time.
    #
    # @return [void]
    def enable(name)
      unless @modules.key?(name)
        $STDERR.puts("Ignored request to enable #{name}': not configured.")
        return
      end
      @enabled_modules << name
    end

    # Starts all enabled modules
    #
    # @api      semipublic
    # @example  Start all enabled modules
    #   ms.start_enabled
    #
    # @return [Array]
    #   The modules that have been started.
    def start_enabled
      @enabled_modules.map(&method(:start))
    end

    # Starts a specific module
    #
    # @api      semipublic
    # @example  Start the module :foo
    #   ms.start(:foo)
    #
    # @param name [Symbol]
    #   The name of the module to start.
    #
    # @return [Object]
    #   The module that has been started.
    def start(name)
      module_class, module_config = @modules.fetch(name)
      module_class.new(*@constructor_arguments).tap do |mod|
        mod.instance_eval(&module_config)
        @module_create_hook.call(name, mod)
      end
    end

    attr_writer :constructor_arguments
    attr_writer :module_create_hook
  end
end
