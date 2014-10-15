require 'ury_rapid/common/types'
require 'ury_rapid/model'

module Rapid
  module Model
    # A creator for stock model components
    #
    # ComponentCreator contains several methods for building commonly used
    # components for models.  It does not register those components with a
    # registrar; to do this, wrap the ComponentCreator in a
    # ComponentCreatorWrapper that calls the registrar as a hook.
    class ComponentCreator
      extend Forwardable

      include Rapid::Common::Types::Validators

      # Initialises a ComponentCreator
      # @return [ComponentCreator]  The initialised ComponentCreator.
      def initialize
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

      # Creates a new playlist item
      #
      # @param options [Hash]
      #   A hash containing the keys :type, :name, :origin, and :duration,
      #   which correspond to the type, name, origin, and duration of the item
      #   respectively.
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

      # Creates a new logger model interface
      #
      # @api public
      # @example Creating a log component for the logger 'logger'.
      #   creator.log(logger)
      # @param logger [Object]
      #   An object that implements the standard library Logger's API.
      # @return [Log]
      #   A Log object that serves as a model interface to the logger.
      def log(logger)
        fail('Nil logger given.') if logger.nil?
        Rapid::Model::Log.new(logger)
      end

      # Creates an arbitrary constant object.
      #
      # ComponentCreator contains methods for building various stock constants,
      # which validate their values before instantiation.  Use of those is
      # recommended where available.
      #
      # @api public
      # @example Creating a constant with value 3 and handler target :target.
      #   # If any response handlers are registered as operating on :target,
      #   # this tree will have those handlers attached to it.
      #   creator.constant(3, :target)
      # @param value [Object]
      #   The value of the constant.
      # @param handler_target [Symbol]
      #   The handler target of the constant.
      # @return [Constant]
      #   A Constant component, holding the given value.
      def constant(value, handler_target)
        Rapid::Model::Constant.new(handler_target, value)
      end

      # Creates an empty tree component
      #
      # A tree is a model object that can contain zero or more other model
      # objects, each identified by an arbitrary ID.
      #
      # @api public
      # @example Creating a tree with handler target :target.
      #   # If any response handlers are registered as operating on :target,
      #   # this tree will have those handlers attached to it.
      #   creator.tree(:target)
      # @param handler_target [Symbol]
      #   The tag used to identify this tree to potential handlers.
      # @return [HashModelObject]
      #   The new tree component.
      def tree(handler_target)
        HashModelObject.new(handler_target)
      end

      # Creates an empty list component
      #
      # A list is a model object that contains an ordered sequence of zero or
      # more model objects.  Each child of a list takes its current index
      # (a natural number starting from zero) as its ID, and the IDs of list
      # children change if objects are inserted or removed before them.
      #
      # @example Creating a list with handler target :target.
      #   # If any response handlers are registered as operating on :target,
      #   # this list will have those handlers attached to it.
      #   creator.list(:target)
      # @param handler_target [Symbol]
      #   The tag used to identify this list to potential handlers.
      # @return [ListModelObject]
      #   The new list component.
      def list(handler_target)
        ListModelObject.new(handler_target)
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
    end
  end
end
