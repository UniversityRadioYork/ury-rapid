require_relative 'codes'

module Bra
  module Baps
    # An object that responds to BAPS server responses by updating the model.
    #
    # The controller subscribes to a response parser's output channel, and
    # responds to incoming responses from that channel by firing methods that
    # update the model to reflect the exposed state of the BAPS server.
    #
    # The BAPS controller also has the ability to respond directly to the BAPS
    # server by sending requests to the outgoing requests queue.  This is used,
    # for example, to complete the BAPS login procedure.
    class Controller
      # Initialises the controller
      #
      # @api semipublic
      #
      # @example Initialise a controller
      #   controller = Controller.new(model, queue)
      #
      # @param model [Model] The Model this Controller will operate on.
      # @param queue [Queue] The queue into which outgoing BAPS requests should
      # be sent.
      def initialize(model, queue)
        @model = model
        @queue = queue
      end

      # Registers the controller's callbacks with a incoming responses channel
      #
      # @api semipublic
      #
      # @example Register an EventMachine channel
      #   controller = Controller.new(model, queue)
      #   channel = EventMachine::Channel.new
      #   # Attach channel to rest of BAPS here
      #   controller.register(channel)
      #
      # @param channel [Channel] The source channel for responses coming from
      #   BAPS's chat system.
      #
      # @return [void]
      def register(channel)
        functions = [
          playback_functions,
          playlist_functions,
          system_functions
        ].reduce({}) { |a, e| a.merge! e }

        channel.subscribe do |response|
          f = functions[response[:code]]
          f.call(response) if f
          unhandled(response) unless f
        end
      end

      private

      # Logs a response with no controller handling function
      #
      # @api private
      #
      # @param response [Hash] A response hash.
      #
      # @return [void]
      def unhandled(response)
        message = "Unhandled response: #{response[:name]}"
        if response[:code].is_a?(Numeric)
          hexcode = response[:code].to_s(16)
          message << " (0x#{hexcode})"
        end
        puts(message)
      end

      # Constructs a response matching hash for playback functions
      #
      # @api private
      #
      # @return [Hash] The response hash, which should be merged into the main
      #   response table.
      def playback_functions
        {
          Codes::Playback::PLAY => set_state_handler(:playing),
          Codes::Playback::PAUSE => set_state_handler(:paused),
          Codes::Playback::STOP => set_state_handler(:stopped),
          Codes::Playback::POSITION => set_marker_handler(:position),
          Codes::Playback::CUE => set_marker_handler(:cue),
          Codes::Playback::INTRO => set_marker_handler(:intro),
          Codes::Playback::LOADED => method(:loaded)
        }
      end

      # Constructs a response matching hash for playlist functions
      #
      # @api private
      #
      # @return [Hash] The response hash, which should be merged into the main
      #   response table.
      def playlist_functions
        {
          Codes::Playlist::DELETE_ITEM => method(:delete_item),
          Codes::Playlist::ITEM_DATA => method(:item_data),
          Codes::Playlist::ITEM_COUNT => method(:item_count),
          Codes::Playlist::RESET => method(:reset)
        }
      end

      # Constructs a response matching hash for system functions
      #
      # @api private
      #
      # @return [Hash] The response hash, which should be merged into the main
      #   response table.
      def system_functions
        {
          Codes::System::CLIENT_ADD => method(:client_add),
          Codes::System::CLIENT_REMOVE => method(:client_remove),
          Codes::System::LOG_MESSAGE => method(:log_message),
          Codes::System::SEED => method(:login_seed),
          Codes::System::LOGIN_RESULT => method(:login_result)
        }
      end

      # Creates a lambda handling state changes for the given state
      #
      # @api private
      #
      # @param state [Symbol] The state that the proc will set players to.
      #
      # @return [Proc] A lambda that takes a BAPS response and sets the
      #   appropriate player state to that provided to this function.
      def set_state_handler(state)
        ->(r) { @model.driver_put_url(player_url(r, 'state'), state) }
      end

      # Creates a lambda handling marker changes for the given marker type
      #
      # @api private
      #
      # @param type [Symbol] The marker type of which the proc will set the
      #   position.
      #
      # @return [Proc] A lambda that takes a BAPS response and sets the
      #   marker identified by the type provided to this function.
      def set_marker_handler(type)
        ->(r) { @model.driver_put_url(player_url(r, type), r[:position]) }
      end

      # Deletes the item identified by the response
      #
      # The response structure must have keys:
      #
      # - :subcode (channel index, starting from 0)
      # - :index (playlist index, starting from 0)
      #
      # @api private
      #
      # @param response [Hash] A response structure.
      #
      # @return [void]
      def delete_item(response)
        id, index = response.values_at(:subcode, :index)

        @model.driver_delete_url("channels/#{id}/playlist/#{index}")
      end

      # Registers an item into channel playlist
      #
      # @api private
      #
      # @param response [Hash] A BAPS response containing the item.
      #
      # @return [void]
      def item_data(response)
        id, index = response.values_at(:subcode, :index)
        type, title = response.values_at(:type, :title)
        item = Bra::Models::Item.new(track_type_baps_to_bra(type), title)

        @model.channel(id).add_item(index, item)
      end

      # Resets a channel playlist
      #
      # @api private
      #
      # @param response [Hash] A response whose subcode is the channel to
      #   reset.
      #
      # @return [void]
      def reset(response)
        @model.driver_delete_url("channels/#{response[:subcode]}")
      end

      # Loads an item into a channel player
      #
      # @api private
      #
      # @param response [Hash] A BAPS response containing the item.
      #
      # @return [void]
      def loaded(response)
        loaded_item(response).each do |key, value|
          @model.driver_put_url(player_url(response, key), value)
        end
      end

      # Intentionally ignores the response
      #
      # @api private
      #
      # @param _ [Hash] The (ignored) response.
      #
      # @return [void]
      def nop(_)
        nil
      end

      alias_method :item_count, :nop
      alias_method :client_add, :nop
      alias_method :client_remove, :nop

      # Logs a BAPS internal message
      #
      # @api private
      #
      # @param response [Hash] The response containing the internal message.
      #
      # @return [void]
      def log_message(response)
        # TODO: actually log this message
        puts "[LOG] #{response[:message]}"
      end

      # Converts an loaded response into a pair of load-state and item
      #
      # @api private
      #
      # @param response [Hash] The loaded response to convert.
      #
      # @return [Array] The following items:
      #   - The loading state (:ok, :loading, :empty or :failed);
      #   - Either nil (no loaded item) or an Item representing the loaded
      #     item.
      def loaded_item(response)
        type, title, duration = response.values_at(:type, :title, :duration)

        load_state = LOAD_STATES[title]
        item = normal_loaded_item(type, title) if load_state == :ok
        {
          duration: duration,
          load_state: load_state,
          item: item
        }
      end

      # Processes a normal loaded item response
      #
      # This converts the response into an item and possibly a duration change.
      #
      # @api private
      #
      # @param type [Symbol] The item type (one of :library, :file or :text).
      # @param title [String] The title to display for the item.
      # @param duration [Fixnum] nil, or the duration of the loaded item.
      #
      # @return [Array] The following items:
      #   - The loading state (:ok, :loading, :empty or :failed);
      #   - Either nil (no loaded item) or an Item representing the loaded
      #     item.
      def normal_loaded_item(type, title)
        Bra::Models::Item.new(track_type_baps_to_bra(type), title)
      end

      # Converts a BAPS track type to a BRA track type
      #
      # @api private
      #
      # @param type [Fixnum] The BAPS track type number.  Must NOT be
      #   Types::Track::NULL.
      #
      # @return [Symbol] The bra equivalent of the BAPS track type (:library,
      #   :file or :text).
      def track_type_baps_to_bra(type)
        fail(InvalidTrackType, type) unless TRACK_TYPE_MAP.include? type
        TRACK_TYPE_MAP[type]
      end

      InvalidTrackType = Class.new(RuntimeError)

      # Receives a seed from the BAPS server and acts upon it
      #
      # @api private
      #
      # @param response [Hash] The BAPS response containing the seed.
      #
      # @return [void]
      def login_seed(response)
        username = @model.find_url('x_baps/server/username', &:value)
        password = @model.find_url('x_baps/server/password', &:value)
        seed = response[:seed]
        # Kurse all SeeDs.  Swarming like lokusts akross generations.
        #   - Sorceress Ultimecia, Final Fantasy VIII
        Commands::Authenticate.new(username, password, seed).run(@queue)
      end

      # Receives a login response from the server and acts upon it
      #
      # @api private
      #
      # @param response [Hash] The BAPS response containing the login result.
      #
      # @return [void]
      def login_result(response)
        code, string = response.values_at(*%i(subcode details))
        is_ok = code == Commands::Authenticate::Errors::OK
        Commands::Synchronise.new.run(@queue) if is_ok
        unless is_ok
          puts("BAPS login FAILED: #{string}, code #{code}.")
          EM.stop
        end
      end

      # Generates an URL to a channel player given a BAPS response
      #
      # The subcode of the BAPS response must be the target channel.
      #
      # @api private
      #
      # @param response [Hash] The response mentioning the channel to use.
      # @param args [Array] A splat of additional model object IDs to form a
      #   sub-URL of the player URL; optional.
      #
      # @return [String] The full model URL.
      def player_url(response, *args)
        ['channels', response[:subcode], 'player', *args].join('/')
      end

      # Hash mapping item names to BRA load states.
      #
      # This is necessary because of the rather odd way in which BAPS signifies
      # loading states other than :ok (that is, inside the track name!).
      LOAD_STATES = Hash.new(:ok).merge!({
        '--LOADING--' => :loading,
        '--LOAD FAILED--' => :failed,
        '--NONE--' => :empty
      })

      # Hash mapping BAPS track type numbers to BRA symbols.
      TRACK_TYPE_MAP = {
        Types::Track::LIBRARY => :library,
        Types::Track::FILE => :file,
        Types::Track::TEXT => :text
      }
    end
  end
end
