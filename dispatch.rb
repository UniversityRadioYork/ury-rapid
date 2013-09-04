module Bra
  # Dispatches responses from the BAPS server to registered handlers.
  class Dispatch
    attr_reader :reader, :writer

    def initialize
      @registered_blocks = Hash.new(
        lambda do |response|
          message = "Unhandled response: #{response[:name]}"
          if response[:code].is_a?(Numeric) then
            hexcode = response[:code].to_s(16)
            message << " (0x#{hexcode})"
          end
          puts message
        end
      )
    end

    # Registers a block as handling a given response from the server.
    def register(command, &block)
      @registered_blocks.update(command => block)
      self
    end

    # Internal: Registers multiple response handlers at once.
    #
    # This is functionally equivalent to mapping the single-command
    # equivalent over the dictionary.
    #
    # handler_hash: A hash mapping response codes to callables.
    #
    # Returns this object, for method chaining.
    def register_response_handlers(handler_hash)
      @registered_blocks.merge! handler_hash
      self
    end

    # Deregisters a previously registered block.
    def deregister(command)
      @registered_blocks.delete(command)
      self
    end

    # Internal: Dispatches a response to the registered response block.
    def emit(response)
      block = @registered_blocks[response[:code]]
      block.call response
    end
  end
end
