require_relative 'model'
require_relative 'channel'
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

      # Public: Create a Model.
      #
      # Returns a Model.
      def create
        root Model do
          child(:channels, ChannelSet) { create_channels }
        end
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

      def create_channels
        num_channels = @options[:num_channels]
        (0...num_channels).each { |i| child(i, Channel) { create_channel } }
      end

      def create_channel
        child(:player, Player) {create_player}
        child :playlist, Playlist
      end

      def create_player
        child :state,      PlayerVariable.make_state
        child :load_state, PlayerVariable.make_load_state
        child :item,       Item.new(:null, nil)
        MARKERS.each { |id| child(id, PlayerVariable.make_marker(id)) }
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
