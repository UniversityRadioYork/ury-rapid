require 'ury-rapid/service_common/requests/null_handler'
require 'ury-rapid/model/component_creator'

module Rapid
  module Model
    class Config
      extend Forwardable

      # Adds extensions to the model
      def_delegator :@handlers, :merge!, :add_handlers
      def_delegator :@options, :[], :option

      # Creates a model object that represents the Rapid log
      def log
        create_model_object(:log, @logger)
      end

      private

      def handler_for(object)
        @handlers[object.handler_target]
      end
    end
  end
end
