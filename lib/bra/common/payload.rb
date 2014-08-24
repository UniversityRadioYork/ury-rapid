require 'active_support/core_ext/object/try'

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
      attr_accessor :privilege_set
      attr_accessor :id

      def initialize(payload, privilege_set, default_id = nil)
        @default_id = default_id
        @payload = payload
        @privilege_set = privilege_set
        @id, @body = flatten_payload
      end

      # Creates a new payload with this payload's privileges but a new body
      def with_body(body)
        self.class.new(body, @privilege_set, @default_id)
      end

      def process(receiver)
        PayloadDispatch.dispatch(@body, receiver)
      end

      # Flattens a payload into an item and target ID
      #
      # @api private
      #
      # @return [Array] A tuple of the target ID and direct object.
      def flatten_payload
        id_mapped_payload? ? flatten_payload! : [@default_id, @payload]
      end

      def flatten_payload!
        id, payload = @payload.flatten
        [make_valid_id(id), payload]
      end

      # Coaxes a payload ID into a valid type
      #
      # This can either be a Symbol or an Integer.
      def make_valid_id(id)
        # This to_s allows IDs that have been symbolised earlier up to be
        # turned into Integers.
        Integer(id.to_s)
      rescue TypeError, RangeError, ArgumentError
        id.to_sym
      end

      # Determines whether a payload is a map from an ID to a payload body
      #
      # @return [Boolean] True if the payload is an ID-map, false otherwise.
      def id_mapped_payload?
        @payload.is_a?(Hash) && @payload.size == 1
      end
    end

    # Method object for processing a payload and sending the results
    class PayloadDispatch
      PROTOCOL_SPLITTER = '://'

      def initialize(body, receiver)
        @body = body
        @receiver = receiver
      end

      # The order of these is important - place specific types before more
      # general ones
      TYPES = %i(hash url integer float string)

      def run
        TYPES.any?(&method(:try_type))
      end

      def self.dispatch(*args)
        new(*args).run
      end

      private

      def try_type(type)
        can_send_type?(type) && validate_and_send(type)
      end

      def can_send_type?(type)
        @receiver.respond_to?(type)
      end

      def validate_and_send(type)
        send("validate_#{type}") { |*valid| @receiver.send(type, *valid) }
      end

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
        protocol, body = @body.split(PROTOCOL_SPLITTER, 2)
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
        body = @body.clone
        type = body.delete(:type).try(:downcase).try(:intern)
        [type, body]
      end

      # Yields a potential URL reference to another resource.
      #
      # @api private
      #
      # @yieldparam [String] The protocol of the URL.
      # @yieldparam [String] The body of the URL.
      #
      # @return [Boolean] true if the body was a URL and was handled; false
      #   otherwise.
      def validate_url
        valid_url?.tap { |valid| yield(*split_url) if valid }
      end

      # Yields the protocol and body of an object if it is a raw string
      #
      # @api private
      #
      # @yieldparam [String] The string object.
      #
      # @return [Boolean] true if the body was a string and was handled; false
      #   otherwise.
      def validate_string
        valid_string?.tap { |valid| yield @body.to_s if valid }
      end

      # Yields the protocol and body of an object if it is an integer
      #
      # @api private
      #
      # @yieldparam [Integer] The integer object.
      #
      # @return [Boolean] true if the body was an integer and was handled;
      #   false otherwise.
      def validate_integer
        valid_integer?.tap { |valid| yield Integer(@body) if valid }
      end

      # Yields the protocol and body of an object if it is a float
      #
      # @api private
      #
      # @yieldparam [Float] The float object.
      #
      # @return [Boolean] true if the body was n float and was handled;
      #   false otherwise.
      def validate_float
        valid_float?.tap { |valid| yield Float(@body) if valid }
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
      def validate_hash
        valid_hash?.tap { |valid| yield(*split_hash) if valid }
      end

      # Whether the payload is a valid hash format payload
      def valid_hash?
        @body.is_a?(Hash)
      end

      # Whether the payload is a valid URL or pseudo-URL
      def valid_url?
        valid_string? && @body.to_s.include?(PROTOCOL_SPLITTER)
      end

      # Whether the payload is a valid plain string
      def valid_string?
        @body.respond_to?(:to_s)
      end

      # Whether the payload is a valid integer
      #
      # This includes values that can be coerced into integers, such as
      # integral strings.
      def valid_integer?
        # A nicer way of doing this would be appreciated.
        # Could use respond_to?(:to_i), but this is too lenient.
        Integer(@body)
        true
      rescue ArgumentError
        false
      end

      # Whether the payload is a valid float
      #
      # This includes values that can be coerced into floats, such as
      # decimal strings.
      def valid_float?
        # A nicer way of doing this would be appreciated.
        Float(@body)
        true
      rescue ArgumentError
        false
      end
    end
  end
end
