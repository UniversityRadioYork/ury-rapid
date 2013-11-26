module Bra
  module Common
    # A wrapper around a PUT/POST payload
    #
    # Payloads come in multiple formats:
    # - A URL payload, which specifies where the resource desired can be
    #   found in terms of a string locator;
    # - A hash payload, which directly specifies the properties the new
    #   resource will have according to some payload 'type';
    # - A hash mapping an ID to one of the above, thus directly specifying
    #   where in the model structure the new resource should go.
    #
    # This object takes a raw payload from the server, alongside the privileges
    # granted to the client sending it is; decides which form of payload it is;
    # then spits out a normalised form of the payload so that the handling
    # objects can interpret it.
    class Payload
      PROTOCOL_SPLITTER = '://'

      attr_accessor :privilege_set
      attr_accessor :id

      def initialize(payload, privilege_set, default_id = nil)
        @default_id = default_id
        @payload = payload
        @privilege_set = privilege_set
        @id, @item = flatten_payload
      end

      def process(options)
        (
          (handle_hash(&options[:hash])       if options.key?(:hash))    ||
          (handle_url(&options[:url])         if options.key?(:url))     ||
          (handle_string(&options[:string])   if options.key?(:string))  ||
          (handle_integer(&options[:integer]) if options.key?(:integer)) ||
          fail("Unknown payload type: #{@item}")
        )
      end

      private

      # Splits a URL or pseudo-URL item into its protocol and body
      #
      # This is useful when handling PUTs or POSTs where the body is a
      # reference to another resource.
      #
      # No URL parsing is done on the body, to allow 'pseudo-URL' schemes
      # where the body is parsed in a non-standard manner.
      #
      # @api private
      #
      # @return [Array] A tuple containing the downcased protocol and
      #   unprocessed body.
      def split_url
        protocol, body = @item.split(PROTOCOL_SPLITTER, 2)
        [protocol.downcase.intern, body]
      end

      # Splits a PUT or POST hash into its type and body
      #
      # This is useful when handling PUTs or POSTs where the body may be
      # interpreted in different ways depending on its type.
      #
      # @api private
      #
      # @return [Array] A tuple containing the downcased type symbol and
      #   unprocessed body.
      def split_hash
        body = @item.clone
        type = body.delete(:type).downcase.intern
        [type, body]
      end

      # Yields the protocol and body of an object if it is a URL
      #
      # This is useful when handling PUTs or POSTs where the body may be a
      # reference to another resource.
      #
      # @api private
      #
      # @yieldparam [String] The protocol of the URL.
      # @yieldparam [String] The body of the URL.
      #
      # @return [Boolean] true if the body was a URL and was handled; false
      #   otherwise.
      def handle_url
        is_valid_url?.tap { |valid| yield(*split_url) if valid }
      end

      # Yields the protocol and body of an object if it is a raw string
      #
      # @api private
      #
      # @yieldparam [String] The string object.
      #
      # @return [Boolean] true if the body was a string and was handled; false
      #   otherwise.
      def handle_string
        is_valid_string?.tap { |valid| yield @item.to_s if valid }
      end

      # Yields the protocol and body of an object if it is an integer
      #
      # @api private
      #
      # @yieldparam [String] The string object.
      #
      # @return [Boolean] true if the body was an integer and was handled;
      #   false otherwise.
      def handle_integer
        is_valid_integer?.tap { |valid| yield @item.to_i if valid }
      end

      # Yields the type and body of an object if it is a hash
      #
      # This is useful when handling PUTs or POSTs where the body is a
      # direct representation, but should be interpreted in different ways
      # depending on its type.
      #
      # @api private
      #
      # @yieldparam [Symbol] The type of the hash, downcased and symbolised.
      # @yieldparam [Hash] The body of the hash.
      #
      # @return [Boolean] true if the body was a hash and was handled; false
      #   otherwise.
      def handle_hash
        is_valid_hash?.tap { |valid| yield(*split_hash) if valid }
      end

      # Whether the payload should be forwarded to the handler intact
      #
      # This method returns true if and only if the forward_proc given in
      # initialisation returns true.
      def is_valid_forward?
        @forward_proc.nil? ? false : @forward_proc.call(@id)
      end

      # Whether the payload is a valid hash format payload
      def is_valid_hash?
        @item.is_a?(Hash) && @item.key?(:type)
      end

      # Whether the payload is a valid URL or pseudo-URL
      def is_valid_url?
        is_valid_string? && @item.include?(PROTOCOL_SPLITTER)
      end

      # Whether the payload is a valid plain string
      def is_valid_string?
        @item.is_a?(String)
      end

      # Whether the payload is a valid integer
      def is_valid_integer?
        @item.respond_to?(:to_i)
      end

      # Flattens a payload into an item and target ID
      #
      # @api private
      #
      # @return [Array] A tuple of the target ID and direct object.
      def flatten_payload
        @payload.is_a?(Hash) ? @payload.flatten : [@default_id, @payload]
      end
    end
  end
end
