require_relative 'model'
require_relative 'set'
require_relative 'playlist'
require_relative 'player'
require_relative 'variable'
require_relative '../common/types'

module Bra
  module Models
    # Option-based creator for models.
    #
    # This performs dependency injection and ensures any model modification
    # handlers specified in the options are set up.
    #
    # It does not handle driver-specific model additions beyond method hook
    # registrations; to add new model trees to the model, pass the result of
    # the model creator to other functions.
    class Creator
      include Bra::Common::Types::Validators

      # Public: Initialise a Creator.
      #
      # options - The options hash to use to create models.
      def initialize(options)
        @options = options
        @channel = EventMachine::Channel.new
        @target = nil
      end

      # Create the model from the given configuration
      #
      # @return [Root]  The finished model.
      def create
        root Root do
          set :players, Player, @options[:players] { player }
          set :playlists, Playlist, @options[:playlists]
        end
      end

      def player
        child :state,      var(:player_state,      play_validator, :stopped)
        child :load_state, var(:player_load_state, load_validator, :empty)
        Bra::Common::Types::MARKERS.each do |id|
          child id, var("player_#{id}".intern, marker_validator, 0)
        end
      end

      def play_validator
        method(:validate_play_state)
      end

      def load_validator
        method(:validate_load_state)
      end

      # Validates an incoming marker
      def marker_validator
        proc do |position|
          position ||= 0
          position_int = Integer(position)
          fail('Position is negative.') if position_int < 0
          # TODO: Check against duration?
          position_int
        end
      end

      private

      def set(id, member_class, ids, &block)
        child id, Set.new(member_class) do
          children(ids, member_class, &block)
        end
      end

      def children(ids, child_class, &block)
        ids.each { |id| child(id, child_class, &block) }
      end

      def root(object, &block)
        object = object.new if object.is_a?(Class)
        register(object)
        build_children(object, &block) if block
        object
      end

      def child(id, object, &block)
        root(object, &block).move_to(@target, id)
      end

      def var(target, validator, initial_value)
        Variable.new(initial_value, validator, target)
      end

      def build_children(object)
        target = @target
        @target = object
        yield
        @target = target
      end

      def register(object)
        register_handlers(object)
        register_update_channel(object)
      end

      def place_in(parent, objects)
        objects.each { |id, object| object.move_to(parent, id) }
      end
      # Attaches HTTP method handlers to a model resource
      #
      # The attached handlers will be @options[NAME][METHOD], where NAME is the
      #   handler_target of the object.
      #
      # @param object [ModelObject] The resource to which the handlers will
      #   be attached.
      #
      # @return [void]
      def register_handlers(object)
        handler = @options[object.handler_target]
        object.register_handler(handler) unless handler.nil?
        warn_no_handler_for(object) if handler.nil?
      end

      # Attaches the updates channel to a model resource
      #
      # The attached channel will be @options[:updates_channel].
      #
      # @param object [ModelObject] The resource to which the handlers will
      #   be attached.
      #
      # @return [void]
      def register_update_channel(object)
        channel = @options[:update_channel]
        object.register_update_channel(channel) unless channel.nil?
        fail('No update channel in @options[:update_channel].') if channel.nil?
      end

      def warn_no_handler_for(object)
        puts("No handler for target #{object.handler_target}.")
      end
    end
  end
end
