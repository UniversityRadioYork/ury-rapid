require 'ury_rapid/common/exceptions'
require 'ury_rapid/services/handler'

module Rapid
  module Services
    module Responses
      # Abstract class for handlers for a given model object
      #
      # Handlers are installed on model objects so that, when the server
      # attempts to modify the model object, the handler translates it into a
      # playout system command to perform the actual playout system event the
      # model change represents.
      class Handler < Rapid::Services::Handler
        extend Forwardable

        # Initialises a responses handler
        #
        # @api public
        def initialize(parent, response)
          super(parent)
          @response = response
          @model = parent.model
        end

        delegate %i(find insert kill replace register
                    create_component) => :model

        # Like kill, but does not fail if the resource does not exist.
        #
        # @api public
        #
        # @return [null]
        def kill_if_exists(*args)
          kill(*args)
        rescue Rapid::Common::Exceptions::MissingResource
          nil
        end

        private

        attr_reader :model
      end
    end
  end
end
