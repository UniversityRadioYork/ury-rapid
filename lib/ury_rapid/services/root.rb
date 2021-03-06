require 'ury_rapid/services/set'

module Rapid
  module Services
    # The root service
    #
    # This is the main service in the Rapid system, and owns all other services
    # as well as the root of the model tree.
    class Root < Rapid::Services::Set
      extend Forwardable

      def initialize(logger, *args)
        super(*args)
        @logger = logger
      end

      def run
        fail 'Nil logger provided.' if @logger.nil?

        make_model

        environment.log(:info, 'Now starting Rapid.')
        environment.log(:info, "Version: #{Rapid::Common::Constants::VERSION}.")

        super
      end

      def make_model
        logger = @logger
        environment.insert_components('/') do
          tree :info, :info do
            ver = Rapid::Common::Constants::VERSION
            constant :version, ver, :version
          end

          log :log, logger
        end
      end
    end
  end
end
