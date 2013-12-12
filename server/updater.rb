module Bra
  module Server
    # An object that serves model updates to clients on WebSockets or streams
    class Updater
      # Initialises the Updater
      #
      # @param model [Model]  The model whose updates channel will notify the
      #   Updater.
      # @param privileges [PrivilegeSet]  The set of privileges available to
      #   the client.
      def initialize(model, privileges)
        @model = model
        @privileges = privileges
        @id = nil
        @to_send = nil
      end

      def stream(stream)
        @send = ->(output) { stream.write(output) }
        register
        stream.callback(&method(:clean_up))
        stream.errback(&method(:clean_up))
      end

      def websocket(websocket)
        @send = ->(output) { websocket.send(output) }
        register
        websocket.onclose(&method(:clean_up))
      end

      private

      def register(&block)
        @id = @model.register_for_updates(&method(:pack_and_send))
      end

      def pack_and_send(update)
        resource, repr = update
        if resource.can?(:get, @privileges)
          json = { resource.url => repr }.to_json
          @send.call("#{json}\n")
        end
      end

      def clean_up
        @model.deregister_from_updates(@id)
        @id = nil
        @send = nil
      end
    end
  end
end
