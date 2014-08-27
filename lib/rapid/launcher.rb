require 'rapid/app'
require 'rapid/common/exceptions'
require 'rapid/common/module_set'
require 'rapid/logger'
require 'rapid/model/config'

module Rapid
  # An object that builds the dependencies for a Rapid App and runs it
  class Launcher
    extend Forwardable

    def initialize(config)
      @services = Rapid::Common::ModuleSet.new()
      @servers = Rapid::Common::ModuleSet.new()

      @user_config = {}

      init_default_makers
      run_config(config)

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

    # Configures the service set for this instance of Rapid
    #
    # See ModuleSet for the DSL accepted by this method.
    def_delegator :@services, :instance_eval, :services

    # Configures the server set for this instance of Rapid
    #
    # See ModuleSet for the DSL accepted by this method.
    def_delegator :@servers, :instance_eval, :servers

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

    ## Makers ##

    # Programmatically build 'make_X_with' DSL methods for each
    # maker.
    %w(app auth channel service_view server_view logger).each do |m|
      attr_writer "#{m}_maker".to_sym
      alias_method "make_#{m}_with".to_sym, "#{m}_maker=".to_sym
    end

    #
    # End configuration DSL
    #

    private

    # Initialises the default set of maker functions
    #
    # These can be overridden in the configuration DSL.
    def init_default_makers
      @app_maker         = Rapid::App.method(:new)
      @auth_maker        = Kankri.method(:authenticator_from_hash)
      @channel_maker     = Rapid::Model::UpdateChannel.method(:new)
      @service_view_maker = Rapid::Model::ServiceView.method(:new)
      @server_view_maker = Rapid::Model::ServerView.method(:new)
      @logger_maker      = Rapid::Logger.method(:default_logger)
    end

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

    def app
      make_app(*app_arguments)
    end

    def app_arguments
      logger = make_logger
      global_service_view, global_server_view = mkmodel(logger)
      services = make_services(logger, global_service_view)
      servers = make_servers(logger, global_server_view)
      [services, servers, global_service_view]
    end

    #
    # Service
    #

    # Initialises all services that are enabled at launch-time
    #
    # See #service and #enable_service in the configuration DSL.
    def make_services(logger, model_view)
      @services.constructor_arguments = [logger]
      @services.module_create_hook =
        ->(name, d) { init_service(name, model_view, d) }
      @services.start_enabled
    end

    def init_service(name, model_view, service)
      sub_structure, register_service_view = service.sub_model(@update_channel)
      sub_model = sub_structure.create
      add_service_model(model_view, name, sub_model)
      init_service_model_view(sub_structure, sub_model, register_service_view)
    end

    def init_service_model_view(sub_structure, sub_model, register_service_view)
      register_service_view.call(make_service_view(sub_model, sub_structure))
    end

    def add_service_model(model_view, name, sub_model)
      model_view.post('', name, sub_model)
    end

    #
    # Model
    #

    def mkmodel(logger)
      structure = @model_structure.new(@update_channel, logger, @model_config)
      model = structure.create
      [make_service_view(model, structure), make_server_view(model)]
    end

    #
    # Server
    #

    # Initialises all server that are enabled at launch-time
    #
    # See #server and #enable_server in the configuration DSL.
    def make_servers(_logger, global_service_view)
      @servers.constructor_arguments = [global_service_view, @auth]
      @servers.start_enabled
    end

    #
    # Constructor delegators
    #

    def_delegator :@app_maker,                :call, :make_app
    def_delegator :@auth_maker,               :call, :make_auth
    def_delegator :@channel_maker,            :call, :make_channel
    def_delegator :@service_view_maker,        :call, :make_service_view
    def_delegator :@logger_maker,             :call, :make_logger
    def_delegator :@server_view_maker,        :call, :make_server_view
  end
end
