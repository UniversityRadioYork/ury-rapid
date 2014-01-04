require 'bra/driver_common/requests/null_handler'
require 'bra/model/component_creator'

module Bra
  module Model
    class Config
      extend Forwardable

      def initialize(structure, update_channel, options)
        @structure = structure
        @extensions = []
        @handlers = Hash.new(Bra::DriverCommon::Requests::NullHandler.new)
        @options = options
        @update_channel = update_channel
        @component_creator = Bra::Model::ComponentCreator.new(self)
      end

      # Adds extensions to the model
      def_delegator :@extensions, :<<, :add_extension
      def_delegator :@handlers, :merge!, :add_handlers
      def_delegator :@options, :[], :option

      def_delegator :@component_creator, :public_send, :create_model_object

      def make
        apply_extensions(make_model_from_structure)
      end

      # @return [self]
      def configure_with(configurator)
        configurator.configure_model(self)
        self
      end

      def register(object)
        register_handler(object)
        register_update_channel(object)
      end

      def register_handler(object)
        object.register_handler(handler_for(object))
      end

      def register_update_channel(object)
        object.register_update_channel(@update_channel)
      end

      private

      def make_model_from_structure
        @structure.new(self).create
      end

      def apply_extensions(root)
        # TODO: Handle strings and other un-instantiated models.
        @extensions.each { |extension| extension.extend(root) }
        root
      end

      def handler_for(object)
        handler = @handlers[object.handler_target]
        puts("#{handler.to_s} -> #{object.handler_target}.")
        handler
      end
    end
  end
end
