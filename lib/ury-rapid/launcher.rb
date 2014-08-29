require 'ury-rapid/app'
require 'ury-rapid/common/exceptions'
require 'ury-rapid/logger'
require 'ury-rapid/modules/set'

module Rapid
  # An object that builds the dependencies for a Rapid App and runs it
  class Launcher
    extend Forwardable

    def initialize(config)
      @services = Rapid::Modules::Set.new
      @servers = Rapid::Modules::Set.new

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
    # See Rapid::Modules::Set for the DSL accepted by this method.
    def_delegator :@services, :instance_eval, :services

    # Configures the server set for this instance of Rapid
    #
    # See Rapid::Modules::Set for the DSL accepted by this method.
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
      @app_maker          = Rapid::App.method(:new)
      @auth_maker         = Kankri.method(:authenticator_from_hash)
      @channel_maker      = Rapid::Model::UpdateChannel.method(:new)
      @service_view_maker = Rapid::Model::ServiceView.method(:new)
      @server_view_maker  = Rapid::Model::ServerView.method(:new)
      @logger_maker       = Rapid::Logger.method(:default_logger)
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
      prepare_service_set(logger, global_service_view)
      prepare_server_set(logger, global_server_view, global_service_view)
      [@services, @servers, global_service_view]
    end

    #
    # Service
    #

    # Prepares the service set for sending to the app
    #
    # See #service and #enable_service in the configuration DSL.
    #
    # @return [void]
    def prepare_service_set(logger, global_service_view)
      @services.constructor_arguments = [logger]
      @services.model_builder = ModelBuilder.new(
        global_service_view, @update_channel, @service_view_maker
      )
    end

    def prepare_module(name, model_view, mod)
      return unless mod.respond_to?(:sub_model)

      sub_structure, register_service_view = mod.sub_model(@update_channel)
      sub_model = sub_structure.create
      add_service_model(model_view, name, sub_model)
      register_service_view.call(make_service_view(sub_model, sub_structure))
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

    # Prepares the server set for sending to the app
    #
    # See #server and #enable_server in the configuration DSL.
    #
    # @return [void]
    def prepare_server_set(_logger, global_server_view, global_service_view)
      @servers.constructor_arguments = [global_server_view, @auth]
      @servers.model_builder = ModelBuilder.new(
        global_service_view, @update_channel, @service_view_maker
      )
    end

    #
    # Constructor delegators
    #

    def_delegator :@app_maker,           :call, :make_app
    def_delegator :@auth_maker,          :call, :make_auth
    def_delegator :@channel_maker,       :call, :make_channel
    def_delegator :@service_view_maker,  :call, :make_service_view
    def_delegator :@logger_maker,        :call, :make_logger
    def_delegator :@server_view_maker,   :call, :make_server_view
  end

  # A class for building the model of a module, given a view into its parent
  class ModelBuilder
    extend Forwardable

    # Initialises the ModelBuilder
    #
    # @api      semipublic
    # @example  Creates a ModelBuilder building into the model pointed to by
    #           model_view.
    #   mb = ModelBuilder.new(model_view)
    #
    # @param service_view [ServiceView]
    #   A service view to use to insert the model into the model tree.
    # @param update_channel [UpdateChannel]
    #   The update channel to provide to the module's model structure.
    # @param service_view_maker [Proc]
    #   A proc that, when called with a model and its structure, returns a
    #   service view of that model.
    def initialize(service_view, update_channel, service_view_maker)
      @service_view       = service_view
      @update_channel     = update_channel
      @service_view_maker = service_view_maker
    end

    # Builds the model for a module, inserting it into the model tree
    #
    # The model will be inserted under the ID `name`.
    #
    # The ModelBuilder will safely ignore modules that do not implement
    # #sub_model.
    #
    # @api      semipublic
    # @example  Builds the model, if any, of the module `foo`, at ID `bar`
    #   mb.build(:bar, foo)
    #
    # @param name [Symbol]
    #   The ID into which the sub-model should be inserted into the model tree
    #   pointed to by @service_view.
    # @param mod [Object]
    #   The module whose model is to be registered into the model tree.
    #
    # @return [void]
    def build(name, mod)
      return unless mod.respond_to?(:sub_model)

      sub_structure, register_service_view = mod.sub_model(@update_channel)
      sub_model = sub_structure.create
      add_model(name, sub_model)
      sub_service_view = make_service_view(sub_model, sub_structure)
      register_service_view.call(sub_service_view)
    end

    # Replaces the service view in this ModelBuilder
    #
    # @return [ModelBuilder]
    #   A new ModelBuilder with the given service view.
    def replace_service_view(new_view)
      ModelBuilder.new(new_view, @update_channel, @service_view_maker)
    end

    private

    # Adds the completed sub-model into the model tree
    #
    # The sub-model is placed into whichever part of the model this
    # ModelBuilder is viewing.
    def add_model(name, sub_model)
      @service_view.post('', name, sub_model)
    end

    def_delegator :@service_view_maker, :call, :make_service_view
  end
end
