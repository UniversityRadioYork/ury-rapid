require 'ury_rapid/app'
require 'ury_rapid/common/exceptions'
require 'ury_rapid/logger'
require 'ury_rapid/modules/root'
require 'ury_rapid/model/composite'

module Rapid
  # An object that builds the dependencies for a Rapid App and runs it
  class Launcher
    extend Forwardable

    def initialize(config)
      @root_config      = nil
      @root_model_class = nil

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

    # Configures the modules set for this instance of Rapid
    #
    # See Rapid::Modules::Root for the DSL accepted by this method.
    def modules(&block)
      fail('Multiple `modules` blocks in config.') unless @root_config.nil?
      @root_config = block
    end

    # Configures the model.
    #
    # @api public
    def model(class_name)
      fail('Multiple `model` blocks in config.') unless @root_model_class.nil?
      @root_model_class = class_name
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
      @app_maker     = Rapid::App.method(:new)
      @auth_maker    = Kankri.method(:authenticator_from_hash)
      @channel_maker = Rapid::Model::UpdateChannel.method(:new)
      @logger_maker  = Rapid::Logger.method(:default_logger)
      @view_maker    = Rapid::Model::View.method(:new)
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
      instance_eval(&config) if     config.is_a?(Proc)
      instance_eval(config)  unless config.is_a?(Proc)
    end

    # @api  private
    def app
      make_app(root_module)
    end

    # @api  private
    def root_module
      logger = make_logger
      root   = make_root(logger)
      root.instance_eval(&@root_config)
      root
    end

    # @api  private
    def make_root(logger)
      model = Rapid::Model::HashModelObject.new(:root)
      model.register_update_channel(@update_channel)
      view = make_view(@authenticator, @update_channel, model, model)
      Rapid::Modules::Root.new(logger, view)
    end

    #
    # Constructor delegators
    #

    def_delegator :@app_maker,     :call, :make_app
    def_delegator :@auth_maker,    :call, :make_auth
    def_delegator :@channel_maker, :call, :make_channel
    def_delegator :@logger_maker,  :call, :make_logger
    def_delegator :@view_maker,    :call, :make_view
  end
end
