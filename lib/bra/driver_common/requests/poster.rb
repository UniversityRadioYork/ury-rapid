require 'bra/driver_common/requests/handler'

module Bra
  module DriverCommon
    module Requests
      # A method object that runs a POST operation on the playout server
      #
      # This should be subclassed to provide the actual functionality for a
      # specific POST operation.
      class Poster < Handler
        extend Forwardable

        # Prevent crashing if the requester tries to register this as a
        # handler.
        TARGETS = []

        # Initialises the Poster
        #
        # @api semipublic
        #
        # @param payload [Payload] The POST payload.
        # @param parent [Object] The object to which requests should be sent.
        # @param object [ModelObject] The object for which this Poster is
        #                             handling a POST.
        # @param default_id [Object] The ID to assign to payloads without a
        #   specific ID.
        def initialize(payload, parent, object)
          super(parent)
          @payload = payload
          @object = object
        end

        # Runs the Poster
        #
        # This tries to interpret the payload as a hash or URL string, by
        # delegating to the post_hash or post_url methods respectively.
        #
        # @api semipublic
        #
        # @example Runs the Poster.
        #   poster.run
        #
        # @return [void]
        def run
          @payload.process(self) unless post_forward
        end

        def_delegator :@object, :id, :caller_id
        def_delegator :@object, :parent_id, :caller_parent_id
        def_delegator :@payload, :id, :payload_id

        # Tries to forward the payload elsewhere
        #
        # By default, this checks to see if the payload has the same ID as one
        # of the target's children and, if so, tries to send it as a PUT
        # request to that object.
        #
        # This should be overridden to catch any child IDs that should be
        # handled as a POST.
        def post_forward
          @object.can_have_children? && try_forward_to_child
        end

        def try_forward_to_child
          child = @object.child(@payload.id)
          child.put(@payload) unless child.nil?
          !child.nil?
        end

        # Wrapper over new and run
        def self.post(*args)
          new(*args).run
        end

        def self.unknown_protocol(protocol)
          fail("Unknown protocol: #{protocol}")
        end

        # Given the ID of a payload, decides whether to forward it elsewhere
        #
        # By default, this is always true.
        #
        # @return [Boolean] true.
        def self.forward_if_id(_)
          true
        end
      end
    end
  end
end
