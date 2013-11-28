require_relative 'model'
require_relative 'channel'
require_relative 'player'

module Bra
  module Models
    # Public: Option-based creator for models.
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
      end

      # Public: Create a Model.
      #
      # Returns a Model.
      def create
        Model.new.tap(&method(:create_channel_set))
      end

      private

      def create_a(cclass, child_maker)
        cclass.new.tap(&method(child_maker)).tap(&method(:register_handlers))
      end

      def create_channel_set(model)
        create_a(ChannelSet, :create_channels).move_to(model, :channels)
      end

      def create_channels(channel_set)
        num_channels = @options[:num_channels]
        (0...num_channels).each { |i| create_channel(channel_set, i) }
      end

      def create_channel(channel_set, index)
        create_a(Channel, :create_channel_children).move_to(channel_set, index)
      end

      def create_channel_children(channel)
        create_player(channel)
        create_playlist(channel)
      end

      def create_player(channel)
        create_a(Player, :create_player_children).move_to(channel, :player)
      end

      def create_player_children(player)
        state = PlayerVariable.make_state.move_to(player, :state)
        register_handlers(state)

        PlayerVariable.make_load_state.move_to(player, :load_state)
        # No handlers for load state, as it's not directly mutable.

        Item.new(:null, nil).move_to(player, :item)

        create_player_markers(player)
      end

      def create_player_markers(player)
        MARKERS.each { |marker| create_player_marker(player, marker) }
      end

      def create_player_marker(player, marker)
        marker = PlayerVariable.make_marker.move_to(player, marker)
        register_handlers(marker)
      end

      def create_playlist(channel)
        playlist = Playlist.new.move_to(channel, :playlist)
        register_handlers(playlist)
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

      def warn_no_handler_for(object)
        puts("No handler for target #{object.handler_target}.") 
      end

      MARKERS = %i(cue position intro duration)
    end
  end
end
