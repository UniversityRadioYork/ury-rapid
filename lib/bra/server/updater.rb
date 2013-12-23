require 'kankri'

module Bra
  module Server
    # Abstract method object that serves a client of the updates API
    #
    # This is implemented by StreamUpdater and WebSocketUpdater.
    class Updater
      extend Forwardable

      # Initialises the Updater
      #
      # @param model [Model]  The model whose updates channel will notify the
      #   Updater.
      def initialize(model)
        @model = model
        @id = nil
        @running = false
      end

      def self.launch(*args)
        new(*args).run
      end

      protected

      def register(&block)
        @id = @model.register_for_updates(&method(:pack_and_send))
        @running = true
      end

      def pack_and_send(update)
        resource, repr = update
        if @privileges && resource.can?(:get, @privileges)
          send_json(type: :update, resource.url => repr)
        end
      end

      def error(message)
        send_json(type: :error, message: message)
      end

      def send_json(raw)
        json = raw.to_json
        send("#{json}\n") if @running
      end

      def clean_up
        @model.deregister_from_updates(@id) unless @id.nil?
        @id = nil
        @running = false
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

      def run
        register
        @stream.callback(&method(:clean_up))
        @stream.errback(&method(:clean_up))
      end
    end

    # An Updater that sends updates to a sinatra-websocket WebSocket
    class WebSocketUpdater < Updater
      def initialize(model, websocket, authenticator, init_privileges)
        super(model)
        @privileges = init_privileges
        @authenticator = authenticator
        @websocket = websocket
      end

      def_delegator :@websocket, :send

      def run
        register
        @websocket.onmessage(&method(:request))
        @websocket.onclose(&method(:clean_up))
      end

      private

      def request(message)
        json = JSON.parse(message)
      rescue JSON::ParserError
        send_json(type: :fail, message: 'Invalid JSON')
      else
        json.deep_symbolize_keys!
        request_json(json)
      end

      def request_json(parsed)
        case parsed[:type]
        when 'auth'
          try_auth(parsed[:username], parsed[:password])
        else
          error("Unknown request: #{parsed[:type]}")
        end
      end

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
