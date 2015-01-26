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
        @ver    = Rapid::Common::Constants::VERSION
      end

      def run
        fail 'Nil logger provided.' if @logger.nil?

        make_model

        environment.log(:info, 'Now starting Rapid.')
        environment.log(:info, "Version: #{@ver}.")

        super
      end

      def make_model
        environment.insert('/', :info, Rapid::Model::HashModelObject.new(:info))
        environment.insert('/info', :version, Rapid::Model::Constant.new(:version, @ver))
        environment.insert('/', :log, Rapid::Model::Log.new(@logger))
      end
    end
  end
end
