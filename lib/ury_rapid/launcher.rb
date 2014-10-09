require 'ury_rapid/app'
require 'ury_rapid/common/exceptions'
require 'ury_rapid/logger'
require 'ury_rapid/modules/root'

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
      logger             = make_logger
      root, builder      = prepare_root(logger)
      root.instance_eval(&@root_config)
      build_root_model(root, builder)
      prepare_root_for_submodules(root, logger)
      root
    end

    # @api  private
    def prepare_root(logger)
      root = Rapid::Modules::Root.new(logger, @root_model_class)

      builder = ModelBuilder.new(nil, @update_channel, @view_maker)

      root.model_builder = builder
      [root, builder]
    end

    # @api  private
    def build_root_model(root, builder)
      builder.build(nil, root)
    end

    # @api  private
    def prepare_root_for_submodules(root, logger)
      root.constructor_arguments = [logger, @auth]
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
    # @param view [View]
    #   A View to use to insert the model into the model tree.
    #   May be null, if the model is to be the root of the tree.
    # @param update_channel [UpdateChannel]
    #   The update channel to provide to the module's model structure.
    # @param view_maker [Proc]
    #   A proc that, when called with a global model, a local model, and its
    #   structure, returns a view of those models.
    def initialize(parent_view, update_channel, view_maker)
      @parent_view    = parent_view
      @update_channel = update_channel
      @view_maker     = view_maker
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
    # @return [Array] A pair of the service view and, if a server view maker
    #   was provided, the server view for the model.
    def build(name, mod)
      return unless mod.respond_to?(:sub_model)

      sub_structure, register_view = mod.sub_model(@update_channel)
      sub_model = sub_structure.create

      sub_view = make_view(name, sub_model, sub_structure)
      register_view.call(sub_view)

      sub_view
    end

    # Replaces the view in this ModelBuilder
    #
    # @return [ModelBuilder]
    #   A new ModelBuilder with the given service view.
    def replace_view(new_view)
      ModelBuilder.new(new_view, @update_channel, @view_maker)
    end

    private

    # Adds the completed sub-model into the model tree
    #
    # The sub-model is placed into whichever part of the model this
    # ModelBuilder is viewing.
    def add_model(name, sub_model)
      @parent_view.insert('', name, sub_model)
    end

    def make_view(name, sub_model, sub_structure)
      if @parent_view.nil?
        @view_maker.call(sub_model, sub_model, sub_structure)
      else
        add_model(name, sub_model)
        @parent_view.with_local_model(sub_model, sub_structure)
      end
    end

    def_delegator :@view_maker, :call, :make_view
  end
end
