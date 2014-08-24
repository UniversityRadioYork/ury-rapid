require 'bra/common/types'
require 'bra/model'

module Bra
  module Model
    module Structures
      # A baseline model structure
      #
      # This contains:
      #   - The info node, which exposes information about the bra system to
      #     clients
      #   - The main system log
      class Standard < Bra::Model::Creator
        include Bra::Common::Types::Validators

        # Create the model from the given configuration
        #
        # @return [Root]  The finished model.
        def create
          root do
            info :info
            log :log
          end
        end

        # Builds the bra information model.
        def info(id)
          hash(id, :info) do
            ver = Bra::Common::Constants::VERSION
            component :version, :constant, ver, :version
          end
        end
      end
    end
  end
end
