require 'bra/common/types'
require 'bra/model'

module Bra
  module Model
    class ComponentCreator
      extend Forwardable

      include Bra::Common::Types::Validators

      def initialize(registrar)
        @registrar = registrar
      end

      def load_state(value)
        validate_then_constant(:validate_load_state, value, :load_state)
      end

      def play_state(value)
        validate_then_constant(:validate_play_state, value, :state)
      end

      def volume(value)
        validate_then_constant(:validate_volume, value, :volume)
      end

      def marker(type, value)
        validate_then_constant(:validate_marker, value, type)
      end

      def item(options)
        Bra::Model::Item.new(
          item_type(options),
          item_name(options),
          item_origin(options),
          item_duration(options)
        )
      end

      def log(logger)
        Bra::Model::Log.new(logger)
      end

      private

      def item_type(options)
        validate_track_type(options.fetch(:type).to_sym)
      end

      def item_name(options)
        options.fetch(:name).to_s
      end

      def item_origin(options)
        origin = options[:origin]
        origin.nil? ? nil : origin.to_s
      end

      def item_duration(options)
        duration = options[:duration]
        duration.nil? ? nil : validate_marker(duration)
      end

      def validate_then_constant(validator, raw_value, handler_target)
        constant(send(validator, raw_value), handler_target)
      end

      def constant(value, handler_target)
        Bra::Model::Constant.new(value, handler_target).tap(&method(:register))
      end

      def_delegator :@registrar, :register
    end
  end
end
