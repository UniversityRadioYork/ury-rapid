module Rapid
  module Common
    # A set of Rapid modules
    #
    # A ModuleSet holds a set of configured Rapid modules (services or servers),
    # as well as information about which modules are enabled at launch-time.
    class ModuleSet
      extend Forwardable

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
        @enabled_modules = Set[]
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
        fail(
          Rapid::Exceptions::BadConfig.new(
            "Tried to enable non-configured module #{name}'."
          )
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
      # This must be performed in the EventMachine run loop.
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

      def_delegator :@enabled_modules, :to_a, :enabled

      attr_writer :constructor_arguments
      attr_writer :module_create_hook
    end
  end
end
