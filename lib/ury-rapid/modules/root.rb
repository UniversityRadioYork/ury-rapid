require 'ury-rapid/model/structures/standard'
require 'ury-rapid/modules/set'

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

      # Initialises the root module
      #
      # @api      public
      # @example  Create a new root module
      #   root = Rapid::Modules::Root.new
      def initialize
        super()

        @model_class = Rapid::Model::Structures::Standard
        @logger      = nil
      end

      attr_writer :model_class
      attr_writer :logger

      # Constructs the sub-model structure for the root module
      #
      # @api  private
      #
      # @param update_channel [Rapid::Model::UpdateChannel]
      #   The update channel that should be used when creating the sub-model
      #   structure.
      #
      # @return [Object]
      #   The sub-model structure.
      def sub_model_structure(update_channel)
        @model_class.new(update_channel, @logger, nil)
      end
    end
  end
end