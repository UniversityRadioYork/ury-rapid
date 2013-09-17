require_relative 'channel'

module Bra
  module Models
    # Public: A player in the model, which represents a channel's currently
    # playing song and its state.
    class Player < ChannelComponent
      # Public: Access the player's current item for reading.
      attr_reader :item

      # Public: Access the player's current state for reading.
      attr_reader :state

      # Public: Access the player's loading state for reading.
      attr_reader :load_state

      # Public: Access the player's current position for reading.
      attr_reader :position

      # Public: Access the player's current position for writing.
      attr_writer :position

      # Public: Access the player's current duration for reading.
      attr_reader :duration

      # Public: Access the player's current duration for writing.
      attr_writer :duration

      # Public: Access the player's current cue position for reading.
      attr_reader :cue

      # Public: Access the player's current cue position for writing.
      attr_writer :cue

      # Public: Access the player's current intro position for reading.
      attr_reader :intro

      # Public: Access the player's current intro position for writing.
      attr_writer :intro

      # Public: Initialises a Player.
      #
      # channel - The channel of the player.
      def initialize(channel)
        super("Player", channel)

        @state = PlayerState.new(self)
        @load_state = PlayerLoadState.new(self)
        @cue = 0
        @intro = 0
        @position = 0
        @duration = 0
        @loaded = nil
      end

      # Public: Retrieves the player's state value.
      #
      # Returns the state value, as a symbol.
      def state_value
        @state.value
      end

      # Public: Change the player model's state.
      #
      # new_state - The symbol representing the new state.
      #
      # Returns nothing.
      def set_state(new_state)
        @state.value = new_state
      end

      # Public: Change the player model's current item and load state.
      #
      # new_state - The symbol (must be one of :ok, :loading or :failed)
      #             representing the new state.
      # new_item  - The Item representing the new loaded item.
      def load(new_state, new_item)
        valid_item = new_item.nil? || new_item.is_a?(Item)
        raise "Not a valid item: #{new_item}" unless valid_item
        @item = new_item

        valid_state = %i(ok loading failed empty).include? new_state
        raise 'Not a valid state' unless valid_state
        set_load_state(new_state)
      end

      # Public: Converts the Player to a hash representation.
      #
      # This conversion is not reversible and may lose some information.
      #
      # Returns a hash representation of the Player.
      def to_hash
        {
          item: @item.to_hash,
          position: position,
          cue: cue,
          intro: intro,
          state: state,
          load_state: load_state
        }
      end

      # Public: Returns the canonical URL of this player.
      #
      # Returns the URL, relative to the API root.
      def url
        [@channel.url, 'player'].join('/')
      end

      # Public: Returns the canonical URL of this player's parent.
      #
      # Returns the URL, relative to the API root.
      def parent_url
        @channel.url
      end

      private

      # Public: Change the player model's load state.
      #
      # new_state - The symbol representing the new state.
      #
      # Returns nothing.
      def set_load_state(new_state)
        @load_state.value = new_state
      end
    end

    class PlayerComponent < ModelObject
      def initialize(name, player)
        super("#{name} (#{player.name}")
        @player = player
      end

      # Internal: Returns the ID of the channel this player component is inside.
      #
      # Returns the channel ID.
      def player_channel_id
        @player.channel_id
      end

      # Internal: Returns the name of the channel this player component is
      # inside.
      #
      # Returns the channel name.
      def player_channel_name
        @player.channel_name
      end
    end

    class PlayerState < PlayerComponent
      attr_reader :value

      def initialize(player)
        super("State", player)
        @value = :stopped
      end

      def value=(new_state)
        valid_state = %i(playing paused stopped).include? new_state
        raise 'Not a valid state' unless valid_state

        @value = new_state
      end

      def to_json
        @value.to_json
      end
    end

    class PlayerLoadState < PlayerComponent
      attr_reader :value

      def initialize(player)
        super("Load State", player)
        @value = :empty
      end

      def value=(new_state)
        valid_state = %i(ok loading failed empty).include? new_state
        raise 'Not a valid load state' unless valid_state

        @value = new_state
      end

      def to_json
        @value.to_json
      end
    end
  end
end
