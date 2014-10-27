module Rapid
  module Services
    # A base class for Rapid services
    #
    # Inheritance of Rapid::Services::Service is not required for Service
    # classes, but is recommended.
    #
    # Subclasses may use the reader #environment to retrieve the Environment
    # with which they can access the rest of the Rapid system.
    class Service
      # Initialises the service
      #
      # @api      semipublic
      # @example  Create a new service
      #   service = Service.new(environment)
      #
      # @param environment [Rapid::Services::Environment]
      #   The Service's environment.
      def initialize(environment)
        @environment = environment
      end

      protected

      # Gets this service's environment
      #
      # @api private
      # @return [Rapid::Services::Environment]
      #   The Service's environment.
      attr_reader :environment
    end
  end
end
