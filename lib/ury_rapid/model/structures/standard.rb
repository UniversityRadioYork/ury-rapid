require 'ury_rapid/common/types'
require 'ury_rapid/model/structures/module_set'

module Rapid
  module Model
    module Structures
      # A baseline root model structure
      #
      # This contains:
      #   - The info node, which exposes information about the Rapid system to
      #     clients
      #   - The main system log
      class Standard < Rapid::Model::Structures::ModuleSet
        include Rapid::Common::Types::Validators

        protected

        # Returns the handler target to attach to this structure's root
        def root_name
          :root
        end

        # Adds extensions to the base module set structure
        def extensions
          info :info
          log :log
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
