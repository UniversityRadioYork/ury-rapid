module Bra
  module Baps
    module Requests
      # Abstract class for handlers for a given model object.
      #
      # DO NOT put this class in the Handlers module.  This will cause the BAPS
      # driver to attempt to register it as a handler, which will fail.
      class Handler
        extend Forwardable

        # Initialises the Handler
        #
        # @api semipublic
        #
        # @example Initialising a Handler with a parent Requester.
        #   queue = EventMachine::Queue.new
        #   requester = Bra::Baps::Requests::Requester.new(queue)
        #   handler = Bra::Baps::Requests::Handler.new(requester)
        #
        # @param parent [Requester] The main Requester to which requests shall
        #   be sent.
        def initialize(parent)
          @parent = parent
        end

        # Splits a URL or pseudo-URL into its protocol and body
        #
        # This is useful when handling PUTs or POSTs where the body is a
        # reference to another resource.
        #
        # No URL parsing is done on the body, to allow 'pseudo-URL' schemes
        # where the body is parsed in a non-standard manner.
        #
        # @api semipublic
        #
        # @example Splitting an HTTP URL.
        #   Handler.split_url('http://example.com')
        #   #=> ['http', 'example.com']
        #
        # @param url [String] The URL, or pseudo-URL, to split.  Must be a
        #   string of the form 'PROTOCOL://BODY', where PROTOCOL and BODY are
        #   any substring (PROTOCOL must not contain '://').
        #
        # @return [Array] A tuple containing the downcased protocol and
        #   unprocessed body.
        def self.split_url(url)
          protocol, body = url.split('://', 2)
          [protocol.downcase, body]
        end

        # Yields the protocol and body of an object if it is a URL
        #
        # This is useful when handling PUTs or POSTs where the body may be a
        # reference to another resource.
        #
        # @api semipublic
        #
        # @example Handling a PUT/POST body that may be a URL.
        #   Handler.handle_url('http://example.com') { |protocol, url| nil }
        #   #=> true
        #   Handler.handle_url(3) { |protocol, url| nil }
        #   #=> false
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
        def self.handle_url(body)
          body.is_a?(String).tap { |isstr| yield *split_url(body) if isstr }
        end

        protected

        # Sends a request to the parent requester
        #
        # @api semipublic
        #
        # @example Sending a request.
        #   request = Bra::Baps::Requests::Request.new(0)
        #   handler.send(request)
        #
        # @param request [Request] A BAPS request in need of sending.
        #
        # @return [void]
        def_delegator(:@parent, :send)

        # Flattens a POST payload into an item and target ID
        #
        # @api semipublic
        #
        # @example Flattening a hash mapping an ID to an item.
        #   handler.flatten_post({ spoo: 10 }, :default)
        #   #=> [:spoo, 10]
        # @example Flattening a direct object to an item.
        #   handler.flatten_post(10, :default)
        #   #=> [:default, 10]
        #
        # @param payload [Object] The payload to flatten, if it is a Hash.
        # @param default_id [Object] The ID to use if the payload is a direct
        #   object (not a Hash).
        #
        # @return [Array] A tuple of the target ID and direct object.
        def self.flatten_post(payload, default_id)
          payload.is_a?(Hash) ? payload.flatten : [default_id, payload]
        end
      end

      # Extension of Handler implementing default behaviour for Variables.
      #
      # By default, the semantics of DELETE on a Variable is that it PUTs the
      # Variable's default initial state.
      class VariableHandler < Handler
        # Requests a DELETE of the given Variable via the BAPS server
        #
        # This effectively sets the Variable to its default value.
        #
        # @api semipublic
        #
        # @example DELETE a Variable
        #   variable_handler.delete(variable)
        # 
        # @param variable [Variable] A model object representing a mutable
        #   variable.
        # 
        # @return (see #put)
        def delete(variable)
          put(variable, variable.initial_value)
        end
      end
    end
  end
end
