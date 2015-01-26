require 'ury_rapid/model'
require 'ury_rapid/common/types'

module Rapid
  module Model
    module Components
      # An object for creating and setting up playout driver components
      class PlayoutModel
        include Rapid::Common::Types::Validators

        # Constructs a PlayoutModel
        #
        # @param update_channel [UpdateChannel]
        #   The update channel to which items will be subscribed after
        #   construction.
        # @param callbacks [Hash]
        #   A dictionary which maps the names of components to procs which,
        #   given the new component and this PlayoutCreator, perform duties
        #   such as assigning handlers.
        def initialize(update_channel, callbacks)
          @update_channel = update_channel
          @callbacks = callbacks
          @callbacks.default_proc = proc do |_, key|
            proc do |component|
              puts "no callback for type #{key} when constructing #{component}"
              component
            end
          end
        end

        # Constructs and returns a channel
        #
        # This may be invoked directly by playout services that own precisely
        # one channel.
        #
        # The channel will be sent through +@callbacks[:channel]+.
        #
        # @return [ModelObject]
        #   A channel.
        def channel
          channel = Rapid::Model::HashModelObject.new(:channel)

          channel.insert(:player, player)
          channel.insert(:playlist, playlist)

          through_callback(:channel, channel)
        end

        # Constructs and returns a player
        #
        # The playlist will be sent through +@callbacks[:player]+.
        #
        # @return [ModelObject]
        #   A player.
        def player
          player = Rapid::Model::HashModelObject.new(:player)

          player.insert(:play_state, play_state(:stopped))
          player.insert(:load_state, load_state(:empty))
          player.insert(:volume, volume(0))
          Rapid::Common::Types::MARKERS.each { |m| player.insert(m, marker(m, 0))}

          through_callback(:player, player)
        end

        # Constructs and returns an empty playlist
        #
        # The playlist will be sent through +@callbacks[:playlist]+.
        #
        # @return [ModelObject]
        #   A playlist.
        def playlist
          playlist = Rapid::Model::ListModelObject.new(:playlist)

          through_callback(:playlist, playlist)
        end

        # Constructs and returns a channel-set tree
        #
        # @param channel_ids [Array]
        #   An array of the IDs of the channels available in this playout system.
        # @return [ModelObject]
        #   A channel set with channels instantiated according to the given IDs.
        def channel_set_tree(channel_ids)
          fail 'Nil channel IDs array given.' if channel_ids.nil?

          channel_set = Rapid::Model::HashModelObject.new(:channel_set)

          channel_ids.each do |channel_id|
            channel_set.insert(channel_id, channel)
          end

          through_callback(:channel_set, channel_set)
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
          through_callback(
            :load_state,
            validate_then_constant(:validate_load_state, value, :load_state)
          )
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
          through_callback(
            :play_state,
            validate_then_constant(:validate_play_state, value, :state)
          )
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
          through_callback(
            :volume,
            validate_then_constant(:validate_volume, value, :volume)
          )
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
          through_callback(
            :marker,
            validate_then_constant(:validate_marker, value, type)
          )
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
          through_callback(
            :item,
            Rapid::Model::Item.new(
              item_type(options),
              item_name(options),
              item_origin(options),
              item_duration(options)
            )
          )
        end

        private

        # Applies the named callback to the given item
        #
        # @param key [Symbol]
        #   The key of the callback to apply.
        # @param item [ModelObject]
        #   The model object to send through a callback.
        #
        # @return [ModelObject]
        #   The result of the callback, if one was registered.
        def through_callback(key, item)

          @callbacks[key].call(item, self)
        end

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
          Rapid::Model::Constant.new(handler_target, send(validator, raw_value))
        end
      end
    end
  end
end
