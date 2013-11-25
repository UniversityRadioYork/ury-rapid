module Bra
  module DriverCommon
    # An object that takes a payload sent to the server and processes it
    #
    # Payloads come in multiple formats:
    # - A URL payload, which specifies where the resource desired can be
    #   found in terms of a string locator;
    # - A hash payload, which directly specifies the properties the new
    #   resource will have according to some payload 'type';
    # - A hash mapping an ID to one of the above, thus directly specifying
    #   where in the model structure the new resource should go.
    #
    # This object takes a raw payload from the server and decides which form
    # of payload it is, then spits out a normalised form of the payload so
    # that the handling objects can interpret it.
    class PayloadProcessor
      PROTOCOL_SPLITTER = '://'

      def initialize(payload, default_id=nil, forward_proc=nil)
        @default_id = default_id
        @payload = payload
        @index, @item = flatten_payload
        @forward_proc = forward_proc
      end

      def process(options)
        (
          (handle_forward(&options[:forward]) if options.key?(:forward)) ||
          (handle_hash(&options[:hash])       if options.key?(:hash))    ||
          (handle_url(&options[:url])         if options.key?(:url))     ||
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
      # @param hash [Hash] The hash to split.  If this contain as a key
      #   the symbol :type, the value of :type will be returned as type;
      #   otherwise, the type will be nil.
      #
      # @return [Array] A tuple containing the downcased type symbol and
      #   unprocessed body.
      def split_hash
        body = @item.clone
        type = body.delete(:type).downcase.intern
        [type, body]
      end

      # Attempts to forward a payload somewhere else
      #
      # This is useful when handling POSTS that translate into PUTs on the
      # original object's children.  For example, a POST of a state to
      # channels/0/player should become a PUT to channels/0/player/state.
      #
      # @api private
      #
      # @return [Boolean] true if the payload was forwarded; false otherwise.
      def handle_forward
        is_valid_forward?.tap { |valid| yield(@index, @item) if valid }
      end

      # Yields the protocol and body of an object if it is a URL
      #
      # This is useful when handling PUTs or POSTs where the body may be a
      # reference to another resource.
      #
      # @api private
      #
      # @param body [String] An object that may be a URL or pseudo-URL.  If
      #   it is a string, it will be handled and the URL yielded to the
      #   block.
      #
      # @yieldparam [String] The protocol of the URL.
      # @yieldparam [String] The body of the URL.
      #
      # @return [Boolean] true if the body was a URL and was handled; false
      #   otherwise.
      def handle_url
        is_valid_url?.tap { |valid| yield *split_url if valid }
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
        is_valid_hash?.tap { |valid| yield *split_hash if valid }
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
        @item.is_a?(String) && @item.include?(PROTOCOL_SPLITTER)
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
