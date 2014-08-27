require 'ury-rapid/common/types'
require 'ury-rapid/model'

module Rapid
  module Model
    module Structures
      # A baseline model structure
      #
      # This contains:
      #   - The info node, which exposes information about the Rapid system to
      #     clients
      #   - The main system log
      class Standard < Rapid::Model::Creator
        include Rapid::Common::Types::Validators

        # Create the model from the given configuration
        #
        # @return [Root]  The finished model.
        def create
          root do
            info :info
            log :log
          end
        end

        # Builds the Rapid information model.
        def info(id)
          hash(id, :info) do
            ver = Rapid::Common::Constants::VERSION
            component :version, :constant, ver, :version
          end
        end
      end
    end
  end
end
