require 'bra/driver_common/requests/handler'

module Bra
  module DriverCommon
    module Requests
      # A request handler that understands URL and hash-based payloads
      #
      # This class expects its subclasses to contain two constants, URL_TYPES
      # and HASH_TYPES, mapping URL protocols and hash type identifiers to
      # methods.
      class UrlHashHandler < Handler
        # Somewhat hacky way of making URL/hash types propagate to subclasses
        # while not polluting UrlHashHandler with their types.
        def self.types
          merge_types(@types || {}, superclass_types)
        end

        # Overlays this class's URL/hash types atop of those of the superclass
        def self.merge_types(our_types, their_types)
          types = their_types.dup

          our_types.keys.each do |key|
            types[key] = types.fetch(key, {}).merge(our_types[key] || {})
          end

          types
        end

        def self.superclass_types
          valid_superclass? ? superclass.types : {}
        end

        def self.valid_superclass?
          superclass.ancestors.include?(UrlHashHandler)
        end

        def self.register_type(style, type, &block)
          @types ||= {}
          @types[style] ||= {}
          @types[style][type] = block
        end

        # Set up the main Poster methods to reference the jump tables above
        %i{url hash}.each do |style|
          define_method(style) do |type, rest|
            instance_exec(rest, &processed_payload_handler(style, type))
          end
        end

        # Shorthand for creating a type valid in both URL and hash forms
        def self.url_and_hash_type(type, url_processor, hash_processor)
          url_type(type) { |url| yield *url_processor.call(url) }
          hash_type(type) { |hash| yield *hash_processor.call(hash) }
        end

        def self.url_type(type, &block)
          register_type(:url, type, &block)
        end

        def self.hash_type(type, &block)
          register_type(:hash, type, &block)
        end

        private

        def processed_payload_handler(style, type)
          self.class.types[style].fetch(type, method(:unsupported_type))
        end

        def unsupported_type(*args)
          fail(Bra::Exceptions::InvalidPayload, 'Invalid payload type.')
        end
      end
    end
  end
end
