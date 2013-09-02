module Bra
  # Dispatches responses from the BAPS server to registered handlers.
  class Dispatch
    attr_reader :reader, :writer

    def initialize(writer, source)
      @writer = writer
      @source = source
      @running = false
      @registered_blocks = Hash.new(
        lambda do |response, listener|
          puts "Unhandled response: 0x#{response[:code].to_s(16)}."
        end
      )
    end

    # Registers a block as handling a given response from the server.
    def register(command, &block)
      @registered_blocks.update(command => block)
      self
    end

    # Deregisters a previously registered block.
    def deregister(command)
      @registered_blocks.delete(command)
      self
    end

    # Pumps the BAPS server for responses until requested to stop.
    def pump_loop
      @running = true
      pump while @running
    end

    # Stops the dispatch loop, if this dispatch is currently in a 'pump_loop'.
    def stop
      @running = false
    end

    private
    def pump
      response = @source.read_response

      block = @registered_blocks[response[:code]]
      block.call(response, self)
    end
  end
end
