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
      end

      # Public: Create a Model.
      #
      # Returns a Model.
      def create
        create_a Model do
          { channels: create_channel_set
          }
        end
      end

      private

      def create_a(cclass, &block)
        create_from(cclass.new, &block)
      end

      def create_from(object, &block)
        register_handlers(object)
        register_update_channel(object)

        place_in(object, block.call) if block

        object
      end

      def place_in(parent, objects)
        objects.each { |id, object| object.move_to(parent, id) }
      end

      def create_channel_set
        create_a(ChannelSet) { create_channels }
      end

      def create_channels
        num_channels = @options[:num_channels]
        Hash[(0...num_channels).map { |i| [i, create_channel] }]
      end

      def create_channel
        create_a Channel do
          { player: create_player,
            playlist: create_playlist
          }
        end
      end

      def create_player
        create_a Player do
          { state: create_from(PlayerVariable.make_state),
            load_state: create_from(PlayerVariable.make_load_state),
            item: Item.new(:null, nil)
          }.merge!(create_player_markers)
        end
      end

      def create_player_markers
        Hash[MARKERS.map { |id| [id, create_player_marker(id)] }]
      end

      def create_player_marker(id)
        create_from(PlayerVariable.make_marker(id))
      end

      def create_playlist
        create_a(Playlist)
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
