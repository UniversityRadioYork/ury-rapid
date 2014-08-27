require 'rapid/common/types'
require 'rapid/model'

module Rapid
  module Model
    # A creator for stock model components
    #
    # ComponentCreator contains several methods for building commonly used
    # components for models.  It also registers components built with it with
    # a specified registrar (usually the model structure), allowing handlers and
    # update channels to be added to the components.
    #
    # Interactions with ComponentCreator usually happen indirectly through a
    # model structure's #component method.
    class ComponentCreator
      extend Forwardable

      include Rapid::Common::Types::Validators

      # Initialises a ComponentCreator
      #
      # @param registrar [Object]  The object responsible for registering
      #   newly built components with their handlers and update channels.
      #
      # @return [ComponentCreator]  The initialised ComponentCreator.
      def initialize(registrar)
        @registrar = registrar
      end

      # Creates a component holding a load state
      #
      # To change the value of the resulting object, replace it with a new
      # load_state component.
      #
      # @param value [Symbol]  The value of the load state component.
      #
      # @return [Constant]  A Constant model object holding a load state.
      def load_state(value)
        validate_then_constant(:validate_load_state, value, :load_state)
      end

      # Creates a component holding a play state
      #
      # To change the value of the resulting object, replace it with a new
      # play_state component.
      #
      # @param value [Symbol]  The value of the play state component.
      #
      # @return [Constant]  A Constant model object holding a play state.
      def play_state(value)
        validate_then_constant(:validate_play_state, value, :state)
      end

      # Creates a component holding a volume
      #
      # To change the value of the resulting object, replace it with a new
      # volume component.
      #
      # @param value [Numeric]  The value of the volume component.
      #
      # @return [Constant]  A Constant model object holding a volume.
      def volume(value)
        validate_then_constant(:validate_volume, value, :volume)
      end

      # Creates a component holding a position marker
      #
      # To change the value of the resulting object, replace it with a new
      # marker component.
      #
      # @param type  [Symbol]   The type symbol of the marker.
      # @param value [Numeric]  The value of the marker component.
      #
      # @return [Constant]  A Constant model object holding a volume.
      def marker(type, value)
        validate_then_constant(:validate_marker, value, type)
      end

      # Creates a new playlist item.
      #
      # @param options [Hash]  A hash containing the keys :type, :name, :origin,
      #   and :duration, which correspond to the type, name, origin, and
      #   duration of the item respectively.
      #
      # @return [Item]  An Item model object holding the playlist item.
      def item(options)
        Rapid::Model::Item.new(
          item_type(options),
          item_name(options),
          item_origin(options),
          item_duration(options)
        )
      end

      # Creates a new logger model interface.
      #
      # @param logger [Object]  An object that implements the standard library
      #   Logger's API.
      #
      # @return [Log]  A Log object that serves as a model interface to the
      #   logger.
      def log(logger)
        Rapid::Model::Log.new(logger)
      end

      # Creates an arbitrary constant object.
      #
      # ComponentCreator contains methods for building various stock constants,
      # which validate their values before instantiation.  Use of those is
      # recommended where available.
      #
      # @param value          [Object]  The value of the constant.
      # @param handler_target [Symbol]  The handler target of the constant.
      #
      # @return [Constant]  A Constant model object holding the constant.
      def constant(value, handler_target)
        Rapid::Model::Constant.new(handler_target, value).tap(&method(:register))
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

      def_delegator :@registrar, :register
    end
  end
end
