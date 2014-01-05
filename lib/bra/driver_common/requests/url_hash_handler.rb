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
        @@types = { url: {}, hash: {} }

        # Set up the main Poster methods to reference the jump tables above
        %i{url hash}.each do |style|
          define_method(style) do |type, rest|
            instance_exec(rest, &processed_payload_handler(style, type))
          end
        end

        def self.url_type(type, &block)
          register_type(:url, type, &block)
        end

        def self.hash_type(type, &block)
          register_type(:hash, type, &block)
        end

        private

        def processed_payload_handler(style, type)
          @@types[style].fetch(type, method(:unsupported_type))
        end

        def self.register_type(style, type, &block)
          @@types[style][type] = block
        end

        def unsupported_type(*args)
          fail(Bra::Exceptions::InvalidPayload, 'Invalid payload type.')
        end
      end
    end
  end
end
