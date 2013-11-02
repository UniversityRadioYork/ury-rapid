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

      def create_component(cclass, child_maker, registrar)
        cclass.new.tap(&method(child_maker)).tap(&method(registrar))
      end

      def create_channel_set(model)
        create_component(
          ChannelSet, :create_channels, :register_channel_set_handlers
        ).move_to(model, :channels)
      end

      def register_channel_set_handlers(channel_set)
        register_handlers(channel_set, :channels_put, :channels_delete)
      end

      def create_channels(channel_set)
        num_channels = @options[:num_channels]
        (0...num_channels).each { |i| create_channel(channel_set, i) }
      end

      def create_channel(channel_set, index)
        create_component(
          Channel, :create_channel_children, :register_channel_handlers
        ).move_to(channel_set, index)
      end

      def create_channel_children(channel)
        create_player(channel)
        create_playlist(channel)
      end

      def register_channel_handlers(channel)
        register_handlers(channel, :channel_put, :channel_delete)
      end

      def create_player(channel)
        create_component(
          Player, :create_player_children, :register_player_handlers
        ).move_to(channel, :player)
      end

      def create_player_children(player)
        state = PlayerVariable.make_state.move_to(player, :state)
        register_handlers(state, :player_state_put, :player_state_delete)

        load = PlayerVariable.make_load_state.move_to(player, :load_state)
        # No handlers for load state, as it's not directly mutatable.

        create_player_markers(player)
      end

      def register_player_handlers(player)
        register_handlers(player, :player_put, :player_delete)
      end

      def create_player_markers(player)
        MARKERS.each { |marker| create_player_marker(player, marker) }
      end

      def create_player_marker(player, marker)
        marker = PlayerVariable.make_marker.move_to(player, marker)
        register_handlers(marker, :marker_put, :marker_delete)
      end

      def create_playlist(channel)
        playlist = Playlist.new.move_to(channel, :playlist)
        register_handlers(playlist, :playlist_put, :playlist_delete)
      end

      # Internal: Attaches HTTP method handlers to a model resource.
      #
      # resource - The resource to whom the handlers will be attached.
      # put      - The handler to call when the resource is PUT.
      # delete   - The handler to call when the resource is DELETEd.
      #
      # Returns nothing.
      def register_handlers(resource, put, delete)
        resource.register_put_handler(
          @options[put]
        ).register_delete_handler(
          @options[delete]
        )
      end

      MARKERS = %i(cue position intro duration)
    end
  end
end
