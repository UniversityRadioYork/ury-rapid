module Bra
  # Public: A class that translates model objects into representations the
  # API app can send to clients.
  class View
    # Public: Initialise the View.
    #
    # model - The model from which the data will be pulled.
    def initialize(model)
      @model = model
    end

    # Public: Create a summary of all channels in the model.
    #
    # Returns an array of channel representation hashes.
    def channels
      @model.channels.map(&(method :channel))
    end

    # Public: Create a summary of the channel with the given ID.
    #
    # channel_id - The channel ID, as an integer starting from 0, or any other
    #              type that can be coerced to an Integer (for example String).
    #
    # Returns a hash representing the channel data.
    def channel_at(channel_id)
      channel raw_channel_at(channel_id)
    end

    # Public: Create a summary of the player of the channel with the given ID.
    #
    # channel_id - The channel ID, as an integer starting from 0, or any other
    #              type that can be coerced to an Integer (for example String).
    #
    # Returns a hash representing the channel data.
    def player_for_channel_at(channel_id)
      player raw_channel_at(channel_id).player
    end

    # Public: Return the player loaded item for the channel with the given ID.
    #
    # channel_id - The channel ID, as an integer starting from 0, or any other
    #              type that can be coerced to an Integer (for example String).
    #
    # Returns a hash representing the item (an empty hash if no item is
    # loaded).
    def player_item_for_channel_at(channel_id)
      loaded = raw_channel_at(channel_id).player.item
      loaded.nil? ? {} : item(loaded)
    end

    # Public: Return the player state for the channel with the given ID.
    #
    # channel_id - The channel ID, as an integer starting from 0, or any other
    #              type that can be coerced to an Integer (for example String).
    #
    # Returns a hash representing the state.
    def player_state_for_channel_at(channel_id)
      { state: (raw_channel_at(channel_id).player.state) }
    end

    # Public: Return the player load state for the channel with the given ID.
    #
    # channel_id - The channel ID, as an integer starting from 0, or any other
    #              type that can be coerced to an Integer (for example String).
    #
    # Returns a hash representing the load state.
    def player_load_state_for_channel_at(channel_id)
      { load_state: (raw_channel_at(channel_id).player.load_state) }
    end

    # Public: Return the player intro position for the channel with the given
    #         ID.
    #
    # channel_id - The channel ID, as an integer starting from 0, or any other
    #              type that can be coerced to an Integer (for example String).
    #
    # Returns a hash representing the intro position.
    def player_intro_for_channel_at(channel_id)
      { intro: (raw_channel_at(channel_id).player.intro) }
    end

    # Public: Return the player cue position for the channel with the given ID.
    #
    # channel_id - The channel ID, as an integer starting from 0, or any other
    #              type that can be coerced to an Integer (for example String).
    #
    # Returns a hash representing the cue position.
    def player_cue_for_channel_at(channel_id)
      { cue: (raw_channel_at(channel_id).player.cue) }
    end

    # Public: Return the player position for the channel with the given ID.
    #
    # channel_id - The channel ID, as an integer starting from 0, or any other
    #              type that can be coerced to an Integer (for example String).
    #
    # Returns a hash representing the position.
    def player_position_for_channel_at(channel_id)
      { position: (raw_channel_at(channel_id).player.position) }
    end

    # Public: Return the playlist for the channel with the given ID.
    #
    # channel_id - The channel ID, as an integer starting from 0, or any other
    #              type that can be coerced to an Integer (for example String).
    #
    # Returns an array representing the playlist data
    def playlist_for_channel_at(channel_id)
      playlist(raw_channel_at(channel_id).items)
    end

    # Public: Return the item at the given index of the playlist for the
    # channel with the given ID.
    #
    # channel_id - The channel ID, as an integer starting from 0, or any other
    #              type that can be coerced to an Integer (for example String).
    # index      - The index into the playlist, also as an integer starting
    #              from 0 or any Integer-coercible type.
    #
    # Returns an array representing the playlist data
    def playlist_item_for_channel_at(channel_id, index)
      item(raw_channel_at(channel_id).items[Integer(index)])
    end

    private

    # Internal: Create a summary of the given channel.
    #
    # channel - The channel object.
    #
    # Returns a hash representing the channel data.
    def channel(channel)
      {
        id: channel.id,
        playlist: playlist(channel.items),
        player: player(channel.player)
      }
    end

    # Internal: Output a summary of a channel's player's state.
    #
    # player - The player whose state is to be summarised.
    #
    # Returns a hash representing the player.
    def player(player)
      {
        state: player.state,
        load_state: player.load_state,
        item: item(player.item),
        position: player.position,
        cue: player.cue,
        intro: player.intro
      }
    end

    # Internal: Output a summary of a channel's playlist
    #
    # items - The playlist to be summarised, as an array of items.
    #
    # Returns an array representing the playlist.
    def playlist(items)
      items.map(&(method :item))
    end

    # Internal: Output a hash representation of an item.
    #
    # item - The item whose hash equivalent is sought.
    #
    # Returns a hash representing item.
    def item(item)
      if item.nil?
        nil
      else
        {
          type: item.type,
          name: item.name
        }
      end
    end

    # Internal: Given a channel ID, find the channel with that ID.
    #
    # channel_id - The channel ID, as an integer starting from 0, or any other
    #              type that can be coerced to an Integer (for example String).
    #
    # Returns the channel, if it exists.
    def raw_channel_at(channel_id)
      id = Integer(channel_id)
      @model.channels[id]
    end
  end
end
