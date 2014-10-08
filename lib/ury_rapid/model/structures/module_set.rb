require 'ury_rapid/model/creator'

module Rapid
  module Model
    module Structures
      # The structure used by module sets
      class ModuleSet < Rapid::Model::Creator
        # Create the model from the given configuration
        #
        # @api      semipublic
        # @example  Create the model
        #   struct.create
        #
        # @return [Constant]  The finished model.
        def create
          root(root_name) do
            extensions
          end
        end

        protected

        # Returns the handler target to attach to this structure's root
        def root_name
          :group_root
        end

        # Hook for adding extensions to the module set structure
        def extensions
        end
      end
    end
  end
end
