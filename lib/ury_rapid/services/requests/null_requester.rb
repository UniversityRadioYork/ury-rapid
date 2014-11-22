module Rapid
  module Services
    module Requests
      # A Requester that installs no requests into the model structure.
      #
      # This is mainly useful for development, but could also be used for
      # NetworkServices that cannot be modified via the model.
      class NullRequester
        # Pretends to add handlers into a model structure.
        #
        # @api      public
        # @example  Add (no) handlers into a structure.
        #   nr = NullRequester.new
        #   nr.add_handlers(structure)
        #
        # @param _structure [Rapid::Model::Creator]
        #   A model structure; ignored.
        #
        # @return [void]
        def add_handlers(_structure)
          # This space intentionally left blank
        end
      end
    end
  end
end
