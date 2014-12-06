require 'ury_rapid/common/exceptions'
require 'ury_rapid/services/service'

module Rapid
  module Services
    # A set of Rapid services
    #
    # A service set holds a set of configured Rapid services, as well as
    # information about which services are enabled at launch-time.
    class Set < Service
      extend Forwardable

      # Initialises a Set
      #
      # @api      semipublic
      # @example  Create a new Set.
      #   set = Set.new(view)
      def initialize(*_)
        super

        @services         = {}
        @enabled_services = ::Set[]
      end

      # Creates a sub-group of this service set
      #
      # @api      semipublic
      # @example  Create a sub-group named :my_group with a service configured
      #   set.group(:my_group) do
      #     set.configure(:a_service_name, Service::Class::Here) do
      #       # Service DSL goes here
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

      # Adds a service and its configuration to this set
      #
      # @api      semipublic
      # @example  Configure a service
      #   set.configure(:a_service_name, Service::Class::Here) do
      #     # Service DSL goes here
      #   end
      #
      # @param name [Symbol]
      #   The name to give to this service instance.
      #
      # @param implementation_class [Class]
      #   The service class.
      #
      # @return [void]
      def configure(name, implementation_class, &block)
        @services[name] = [implementation_class, block]
      end

      # Enables a configured service at load-time
      #
      # @api      semipublic
      # @example  Enable a service
      #   set.enable(:a_service_name)
      #
      # @param name [Symbol]
      #   The name of the service to enable at load-time.
      #
      # @return [void]
      def enable(name)
        fail(
          Rapid::Common::Exceptions::BadConfig,
          "Tried to enable non-configured service #{name}'."
        ) unless @services.key?(name)

        @enabled_services << name
      end

      # Enables all previously configured services
      #
      # @api      semipublic
      # @example  Enable a service
      #   set.enable(:a_service_name)
      #
      # @return [void]
      def enable_all
        @services.each_key(&method(:enable))
      end

      # Starts a specific service
      #
      # This should be performed in the EventMachine run loop, as certain
      # services will spin up EventMachine tasks here.
      #
      # @api      semipublic
      # @example  Start the service :foo
      #   set.start(:foo)
      #
      # @param name [Symbol]
      #   The name of the service to start.
      #
      # @return [void]
      def start(name)
        service_class, service_config = @services.fetch(name)
        environment.insert_components('/') { tree(name, :sub_root) }
        service_view = environment.with_local_root(environment.find("/#{name}"))
        mod = service_class.new(service_view)
        mod.instance_eval(&service_config)
        mod.run
      end

      # Starts all enabled services
      #
      # @api      semipublic
      # @example  Start all enabled services
      #   set.start_enabled
      #
      # @return [void]
      def start_enabled
        @enabled_services.each(&method(:start))
      end

      def_delegator :@enabled_services, :to_a, :enabled

      # Lists the disabled services
      #
      # @api      semipublic
      # @example  List the disabled services
      #   # Assuming :a, :b, and :c are disabled
      #   set.disable
      #   #=> [:a, :b, :c]
      #
      # @return [Array]
      #   An array containing the names of the disabled, but configured,
      #   services available in this service set.
      def disabled
        @services.each_key.reject { |n| @enabled_services.include?(n) }.to_a
      end

      attr_writer :constructor_arguments
      attr_writer :model_builder

      # Runs the services set.
      #
      # Running the service set entails starting all of the service set's
      # enabled services.
      #
      # @api      semipublic
      # @example  Runs a service set.
      #   set.run
      #
      # @return [void]
      def run
        start_enabled
      end
    end
  end
end
