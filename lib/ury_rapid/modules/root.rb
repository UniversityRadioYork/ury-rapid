require 'ury_rapid/modules/set'

module Rapid
  module Modules
    # The root module
    #
    # This is the main module in the Rapid system, and owns all other modules
    # as well as the root of the model tree.
    #
    # The root module's model is different, in that it is not built using a
    # module set's model builder.  Instead, the Launcher brings up the model
    # in a way such that it needs no service or server views to create.
    class Root < Rapid::Modules::Set
      extend Forwardable

      def initialize(logger, view)
        super(view)
        @logger = logger
      end

      def run
        fail 'Nil logger provided.' if @logger.nil?

        logger = @logger
        view.insert_components('/') do
          hash :info, :info  do
            ver = Rapid::Common::Constants::VERSION
            constant :version, ver, :version
          end

          log :log, logger
        end

        view.log(:info, 'Now starting Rapid.')
        view.log(:info, "Version: #{Rapid::Common::Constants::VERSION}.")

        super
      end
    end
  end
end
