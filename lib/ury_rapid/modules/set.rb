require 'ury_rapid/common/exceptions'

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
      # @api      semipublic
      # @example  Create a new Set.
      #   ms = Set.new(view)
      def initialize(view)
        @modules         = {}
        @enabled_modules = ::Set[]
        @view            = view
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
        configure(name, Set) do
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
        @view.insert_components('/') do
          hash name, :sub_root
        end
        module_view = @view.with_local_root(@view.find("/#{name}"))
        mod = module_class.new(module_view)
        mod.instance_eval(&module_config)
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

      protected

      attr_reader :view
    end
  end
end
