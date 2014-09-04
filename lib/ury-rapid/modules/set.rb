require 'ury-rapid/common/exceptions'

module Rapid
  module Modules
    # A set of Rapid modules
    #
    # A module set holds a set of configured Rapid modules (services or
    # servers), as well as information about which modules are enabled at
    # launch-time.
    class Set
      extend Forwardable

      # Initialises a Set
      #
      # The Set, by default, passes nothing to module constructors, and
      # does nothing with the modules after construction.  Use
      # #constructor_arguments= and #module_builder= to override this.
      #
      # @api      semipublic
      # @example  Create a new Set with no constructor arguments provided.
      #   ms = Set.new
      def initialize(*constructor_arguments)
        @modules = {}
        @enabled_modules = ::Set[]
        @constructor_arguments = constructor_arguments
        @model_builder = nil
      end

      # Creates a sub-group of this module set
      #
      # @api      semipublic
      # @example  Create a sub-group named :my_group with a module configured
      #   ms.group(:my_group) do
      #     ms.configure(:a_module_name, Module::Class::Here) do
      #       # Module DSL goes here
      #     end
      #   end
      #
      # @param name [Symbol]
      #   The name to give to this sub-group.
      #
      # @return [void]
      def group(name, &block)
        # This needs to be a procedure as the model builder won't have been
        # assigned to this set at the time #group is called, but it will have
        # been when the #configure block is called.
        builder_proc = ->() { @model_builder }

        configure(name, Set) do
          builder = builder_proc.call
          fail("Found nil model builder at group #{name}.") if builder.nil?

          send(:model_builder=, builder)
          instance_eval(&block)
        end
      end

      # Adds a module and its configuration to this set
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
        fail(
          Rapid::Common::Exceptions::BadConfig,
          "Tried to enable non-configured module #{name}'."
        ) unless @modules.key?(name)

        @enabled_modules << name
      end

      # Enables all previously configured modules
      #
      # @api      semipublic
      # @example  Enable a module
      #   ms.enable(:a_module_name)
      #
      # @param name [Symbol]
      #   The name of the module to enable at load-time.
      #
      # @return [void]
      def enable_all
        @modules.each_key(&method(:enable))
      end

      # Starts a specific module
      #
      # This should be performed in the EventMachine run loop, as certain
      # modules will spin up EventMachine tasks here.
      #
      # @api      semipublic
      # @example  Start the module :foo
      #   ms.start(:foo)
      #
      # @param name [Symbol]
      #   The name of the module to start.
      #
      # @return [void]
      def start(name)
        module_class, module_config = @modules.fetch(name)
        mod = module_class.new(*@constructor_arguments)
        mod.instance_eval(&module_config)
        @model_builder.build(name, mod)
        mod.run
      end

      # Starts all enabled modules
      #
      # @api      semipublic
      # @example  Start all enabled modules
      #   ms.start_enabled
      #
      # @return [void]
      def start_enabled
        @enabled_modules.each(&method(:start))
      end

      def_delegator :@enabled_modules, :to_a, :enabled

      # Lists the disabled modules
      #
      # @api      semipublic
      # @example  List the disabled modules
      #   # Assuming :a, :b, and :c are disabled
      #   ms.disable
      #   #=> [:a, :b, :c]
      #
      # @return [Array]
      #   An array containing the names of the disabled, but configured,
      #   modules available in this module set.
      def disabled
        @modules.each_key.reject { |n| @enabled_modules.include?(n) }.to_a
      end

      attr_writer :constructor_arguments
      attr_writer :model_builder

      # Runs the module set.
      #
      # Running the module set entails starting all of the module set's enabled
      # modules.
      #
      # @api      semipublic
      # @example  Runs a module set.
      #   ms.run
      #
      # @return [void]
      def run
        start_enabled
      end

      # Asks the module set to prepare its sub-model structure
      #
      # @api      semipublic
      # @example  Request the sub-model structure of the sub-group
      #   sub_model, register_view_proc = set.sub_model
      #
      # @param update_channel [Rapid::Model::UpdateChannel]
      #   The update channel that should be used when creating the sub-model
      #   structure.
      #
      # @return [Array]
      #   A tuple of the completed sub-model structure, and a proc that should
      #   be called with a ServiceView of the completed model.
      def sub_model(update_channel)
        [sub_model_structure(update_channel), method(:service_view=)]
      end

      # Constructs the sub-model structure for this set
      #
      # @api  private
      #
      # @param update_channel [Rapid::Model::UpdateChannel]
      #   The update channel that should be used when creating the sub-model
      #   structure.
      #
      # @return [Object]
      #   The sub-model structure.
      def sub_model_structure(update_channel)
        Rapid::Model::Structures::ModuleSet.new(update_channel, nil, {})
      end

      def service_view=(new_view)
        @service_view = new_view

        return if @model_builder.nil?
        @model_builder = @model_builder.replace_service_view(@service_view)
      end
    end
  end
end
