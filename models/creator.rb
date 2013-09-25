require_relative 'model'
require_relative 'channel'
require_relative 'player'

module Bra
  module Models
    # Public: Option-based creator for models.
    #
    # This performs dependency injection and ensures any model modification
    # handlers specified in the options are set up.
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
        model = Model.new

        create_channels(model)

        model
      end

      private

      def create_channels(model)
        num_channels = @options[:num_channels]

        channels = ChannelSet.new
        (0...num_channels).each { |i| create_channel(channels, i) }
        channels.move_to(model, :channels)
      end

      def create_channel(channel_set, index)
        channel = Channel.new
        channel.move_to(channel_set, index)

        create_player(channel)
        create_playlist(channel)
      end

      def create_player(channel)
        player = Player.new.move_to(channel, :player)

        PlayerVariable.make_state.move_to(player, :state)
        PlayerVariable.make_load_state.move_to(player, :load_state)

        %i(cue position intro duration).each do |marker|
          PlayerVariable.make_marker.move_to(player, marker)
        end
      end

      def create_playlist(channel)
        Playlist.new.move_to(channel, :playlist)
      end
    end
  end
end
