require_relative 'model'
require_relative 'playlist'
require_relative 'player'

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
          child(:playlists, PlaylistSet) { playlists }
          child(:players,   PlayerSet)   { players   }
        end
      end

      def playlists
        @options[:playlists].each { |i| child(i, Playlist) }
      end

      def players
        @options[:players].each { |i| child(i, Player) { player } }
      end

      def player
        child :state,      PlayerVariable.make_state
        child :load_state, PlayerVariable.make_load_state
        child :item,       Item.new(:null, nil)
        MARKERS.each { |id| child(id, PlayerVariable.make_marker(id)) }
      end

      private

      def root(object, &block)
        object = object.new if object.is_a?(Class)
        register(object)
        build_children(object, &block) if block
        object
      end

      def child(id, object, &block)
        object = object.new if object.is_a?(Class)
        object.move_to(@target, id)
        register(object)
        build_children(object, &block) if block
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

      MARKERS = %i(cue position intro duration)
    end
  end
end
