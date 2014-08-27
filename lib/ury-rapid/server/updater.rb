require 'kankri'

module Rapid
  module Server
    # Abstract method object that serves a client of the updates API
    #
    # This is implemented by StreamUpdater and WebSocketUpdater.
    class Updater
      extend Forwardable

      # Initialises the Updater
      #
      # @api  private
      #
      # @param model [Model]  The model whose updates channel will notify the
      #   Updater.
      def initialize(model)
        @model = model
        @id = nil
        @running = false
      end

      # Launches an Updater
      #
      # This is shorthand for initialising an Updater, then calling #run.
      def self.launch(*args)
        new(*args).run
      end

      # Runs the Updater
      def run
        register
        on_message(&method(:request))
        on_close(&method(:clean_up))
      end

      protected

      attr_reader :running

      def register(&_)
        @id = @model.register_for_updates(&method(:pack_and_send))
        @running = true
      end

      # Packs and sends an update
      #
      # The update will be sent if, and only if, this Updater has sufficient
      # privileges to GET the updated resource.
      #
      # @api  private
      #
      # @param update [List]
      #   A pair of the resource that has been updated, and a representation of
      #   the update on the resource that should be sent through the Updater.
      #
      # @return [void]
      def pack_and_send(update)
        resource, repr = update
        return unless @privileges && resource.can?(:get, @privileges)
        send_json(type: :update, resource.url => repr)
      end

      # Sends an error message via the Updater
      #
      # @api  private
      #
      # @param message [String]
      #   The error message to send through the Updater.
      #
      # @return [void]
      def error(message)
        send_json(type: :error, message: message)
      end

      # Sends the JSON representation of an object via the Updater
      #
      # The send is scheduled on the event loop, but will not occur if the
      # Updater has closed down by the time the send fires.
      #
      # @api  private
      #
      # @param raw [Object]
      #   The object to convert to JSON and send through the Updater.
      #
      # @return [void]
      def send_json(raw)
        json = raw.to_json
        EM.next_tick { send("#{json}\n") if running }
      end

      def clean_up
        @running = false
        @model.deregister_from_updates(@id) unless @id.nil?
        @id = nil
      end
    end

    # An Updater that sends updates to a HTTP stream
    class StreamUpdater < Updater
      def initialize(model, stream, privileges)
        super(model)
        @privileges = privileges
        @stream = stream
      end

      def_delegator :@stream, :write, :send

      # Dummy method for registering an on-message callback
      #
      # HTTP streams are incapable of receiving messages, so this is a no-op.
      def on_message
        # Can't receive messages from the stream
      end

      # Dummy method for handling updater requests
      #
      # HTTP streams are incapable of receiving requests, so this is a no-op.
      def request
        # Can't take requests from the stream
      end

      # Registers a block to call when the stream closes
      #
      # The block receives no parameters.
      #
      # @api semipublic
      def on_close(&block)
        @stream.callback(&block)
        @stream.errback(&block)
      end
    end

    # An Updater that sends updates to a sinatra-websocket WebSocket
    class WebSocketUpdater < Updater
      # Initialises a WebSocketUpdater
      #
      # @api      public
      # @example  Initialise a WebSocketUpdater.
      #   WebSocketUpdater.new(model, websocket, authenticator, privs)
      #
      # @param model [Model]
      #   The model to which this Updater will subscribe for updates.
      # @param websocket [Object]
      #   The WebSocket to which this Updater will send updates, and from which
      #   this Updater will receive requests.
      # @param authenticator [Object]
      #   An object providing authentication services, to be used for
      #   authenticating on the WebSocket.
      # @param init_privileges [Object]
      #   The initial set of privileges to give to this Updater.  These may be
      #   replaced by the client by sending an authentication request.
      def initialize(model, websocket, authenticator, init_privileges)
        super(model)
        @privileges = init_privileges
        @authenticator = authenticator
        @websocket = websocket
      end

      def_delegator :@websocket, :send
      def_delegator :@websocket, :onmessage, :on_message
      def_delegator :@websocket, :onclose, :on_close

      private

      # Determines whether the WebSocketUpdater is running
      #
      # @api  private
      #
      # @return [void]
      def running
        super() && @websocket.state == :connected
      end

      # Handles a WebSocket request
      #
      # Since the request comes in as JSON, this method first parses the JSON,
      # and sends the parsed result to #request_json.
      #
      # @api  private
      #
      # @param message [String]
      #   The JSON request to handle.
      #
      # @return [void]
      def request(message)
        json = JSON.parse(message)
      rescue JSON::ParserError
        send_json(type: :fail, message: 'Invalid JSON')
      else
        json.deep_symbolize_keys!
        request_json(json)
      end

      # Handles a parsed WebSocket request
      #
      # Currently, the following requests are supported:
      #
      # * `auth` (`username`, `password`): Authenticates this WebSocket,
      #   allowing access to requests and updates with the privileges of the
      #   authenticated user.
      #
      # @api  private
      #
      # @param parsed [Hash]
      #   The parsed JSON request to handle.
      #
      # @return [void]
      def request_json(parsed)
        case parsed[:type]
        when 'auth'
          try_auth(parsed[:username], parsed[:password])
        else
          error("Unknown request: #{parsed[:type]}")
        end
      end

      # Tries to authenticate on the WebSocket
      #
      # This is part of the in-band authentication handling for a WebSocket:
      # an `auth` request via the WebSocket triggers a #try_auth.
      #
      # If the authentication is successful, the username is returned in an
      # `auth` response and the WebSocket will operate with the privileges of
      # the authenticated user.  Otherwise, an error is returned.
      #
      # @api  private
      #
      # @param username [String]  The username used to authenticate.
      # @param password [String]  The password used to authenticate.
      #
      # @return [void]
      def try_auth(username, password)
        new_privileges = @authenticator.call(username, password)
        @privileges = new_privileges
        send_json(type: :auth, username: username)
      rescue Kankri::AuthenticationFailure
        error('Authentication failed.')
      end
    end
  end
end
