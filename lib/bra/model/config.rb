module Bra
  module Model
    class Config
      def initialize(update_channel, options)
        @extensions = []
        @handlers = []
        @options = options
        @update_channel = update_channel
      end

      # Adds extensions to the model
      def_delegator :@extensions, :<<, :add_extension
      def_delegator :@options, :[], :option

      def make
        apply_extensions(make_model_from_structure)
      end

      def configure_with(configurator)
        configurator.configure_model(self)
      end

      def register_handler(object)
        object.register_handler(handler_for(object))
      end

      def register_update_channel(object)
        object.register_update_channel(@update_channel)
      end

      private

      def make_model_from_structure
        make_model_from(structure)
      end

      def make_model_from(structure)
        init_structure(structure).create(self)
      end

      def init_structure(structure)
        require structure
        Structure.new(full_config)
      end

      def structure
        options[:source]
      end

      def apply_extensions(root)
        # TODO: Handle strings and other un-instantiated models.
        @extensions.each { |extension| extension.extend(root) }
        root
      end

      def handler_for(object)
        handler = @handlers[object.handler_target]
        warn_no_handler_for(object) if handler.nil?
      end

      def warn_no_handler_for(object)
        puts("No handler for target #{object.handler_target}.")
      end
    end
  end
end
