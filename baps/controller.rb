require_relative 'codes'

module Bra
  module Baps
    # Internal: An object that responds to BAPS server responses by updating
    # the model.
    class Controller
      # Internal: Initialises the controllers.
      #
      # model - The Model this Controller will operate on.
      # queue - The queue into which BAPS requests should be sent.
      def initialize(model, queue)
        @model = model
        @queue = queue
      end

      # Internal: Registers the controller's callbacks with a response
      # dispatch.
      #
      # dispatch - The object sending responses to listeners.
      #
      # Returns nothing.
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

      def unhandled(response)
        message = "Unhandled response: #{response[:name]}"
        if response[:code].is_a?(Numeric)
          hexcode = response[:code].to_s(16)
          message << " (0x#{hexcode})"
        end
        puts(message)
      end

      # Internal: Register playback response handler functions.
      #
      # Returns nothing.
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

      # Internal: Register playlist response handler functions.
      #
      # Returns nothing.
      def playlist_functions
        {
          Codes::Playlist::ITEM_DATA => method(:item_data),
          Codes::Playlist::ITEM_COUNT => method(:item_count),
          Codes::Playlist::RESET => method(:reset)
        }
      end

      # Internal: Register system response handler functions.
      #
      # Returns nothing.
      def system_functions
        {
          Codes::System::CLIENT_ADD => method(:client_add),
          Codes::System::CLIENT_REMOVE => method(:client_remove),
          Codes::System::LOG_MESSAGE => method(:log_message),
          Codes::System::SEED => method(:login_seed),
          Codes::System::LOGIN_RESULT => method(:login_result)
        }
      end

      # Internal: Creates a proc that will handle a state change for the
      # given state.
      #
      # state - The state that the proc will set players to.
      #
      # Returns a proc that takes a BAPS response and sets the appropriate
      #   player state to that provided to this function.
      def set_state_handler(state)
        ->(r) { @model.driver_put_url(player_url(r, 'state'), state) }
      end

      # Internal: Creates a proc that will handle a marker change for the
      # given marker type.
      #
      # type - The marker type of which the proc will set the position.
      #
      # Returns a proc that takes a BAPS response and sets the appropriate
      #   marker of the type provided to this function.
      def set_marker_handler(type)
        ->(r) { @model.driver_put_url(player_url(r, type), r[:position]) }
      end

      def item_data(response)
        id, index = response.values_at(:subcode, :index)
        type, title = response.values_at(:type, :title)
        item = Bra::Models::Item.new(track_type_baps_to_bra(type), title)

        @model.channel(id).add_item(index, item)
      end

      def reset(response)
        @model.driver_delete_url("channels/#{response[:subcode]}")
      end

      def loaded(response)
        loaded_item(response).each do |key, value|
          @model.driver_put_url(player_url(response, key), value)
        end
      end

      # Intentionally ignores the response.
      # 
      # @param _ [Hash] The (ignored) response.
      #
      # @return [NilClass] nil.
      def nop(_)
          nil
      end

      alias_method :item_count, :nop
      alias_method :client_add, :nop
      alias_method :client_remove, :nop

      def log_message(response)
        # TODO: actually log this message
        puts "[LOG] #{response[:message]}"
      end

      # Internal: Converts an loaded response into a pair of load-state and
      # item.
      #
      # response - The loaded response to convert.
      #
      # Returns a list with the following items:
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

      # Internal: Processes a normal loaded item response, converting it into
      # an item and possibly a duration change.
      #
      # type     - The item type (one of :library, :file or :text).
      # title    - The title to display for the item.
      # duration - Nil, or the duration of the loaded item.
      #
      # Returns a list with the following items:
      #   - The loading state (:ok, :loading, :empty or :failed);
      #   - Either nil (no loaded item) or an Item representing the loaded
      #     item.
      def normal_loaded_item(type, title)
        Bra::Models::Item.new(track_type_baps_to_bra(type), title)
      end

      # Internal: Converts a BAPS track type to a BRA track type.
      #
      # type - The BAPS track type number.  Must NOT be Types::Track::NULL.
      #
      # Returns a symbol (:library, :file or :text) being the BRA equivalent of
      # the BAPS track type.
      def track_type_baps_to_bra(type)
        fail(InvalidTrackType, type) unless TRACK_TYPE_MAP.include? type
        TRACK_TYPE_MAP[type]
      end

      InvalidTrackType = Class.new(RuntimeError)

      # Receive a seed from the BAPS server and act upon it.
      #
      # response - The BAPS response containing the seed.
      #
      # Returns nothing.
      def login_seed(response)
        username = @model.find_url('x_baps/server/username', &:value)
        password = @model.find_url('x_baps/server/password', &:value)
        seed = response[:seed]
        # Kurse all SeeDs.  Swarming like lokusts akross generations.
        #   - Sorceress Ultimecia, Final Fantasy VIII
        Commands::Authenticate.new(username, password, seed).run(@queue)
      end

      # Receive a login response from the server and act upon it.
      #
      # response - The BAPS response containing the login result.
      #
      # Returns nothing.
      def login_result(response)
        code, string = response.values_at(*%i(subcode details))
        is_ok = code == Commands::Authenticate::Errors::OK
        Commands::Synchronise.new.run(@queue) if is_ok
        unless is_ok
          puts("BAPS login FAILED: #{string}, code #{code}.")
          EM.stop
        end
      end

      # Generates an URL to a channel player, given a BAPS response whose
      # subcode is the target channel.
      #
      # @param response [Hash] The response mentioning the channel to use.
      # @param args [Array] A splat of additional model object IDs to form a
      #   sub-URL of the player URL; optional.
      #
      # @return [String] The full model URL.
      def player_url(response, *args)
        ['channels', response[:subcode], 'player', *args].join('/')
      end

      # Internal: Hash mapping item names to BRA load states.
      #
      # This is necessary because of the rather odd way in which BAPS signifies
      # loading states other than :ok (that is, inside the track name!).
      LOAD_STATES = Hash.new(:ok).merge!({
        '--LOADING--' => :loading,
        '--LOAD FAILED--' => :failed,
        '--NONE--' => :empty
      })

      # Internal: Hash mapping BAPS track type numbers to BRA symbols.
      TRACK_TYPE_MAP = {
        Types::Track::LIBRARY => :library,
        Types::Track::FILE => :file,
        Types::Track::TEXT => :text
      }
    end
  end
end
