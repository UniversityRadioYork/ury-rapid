require_relative 'handler.rb'
require_relative '../../driver_common/payload_processor'

module Bra
  module Baps
    module Requests
      # A method object that runs a POST operation on the playout server
      #
      # This should be subclassed to provide the actual functionality for a
      # specific POST operation.
      class Poster < Handler
        # Prevent crashing if the requester tries to register this as a
        # handler.
        TARGETS = []

        # Initialises the Poster
        #
        # @api semipublic
        #
        # @param payload [PayloadProcessor] The payload processor containing
        #   the POST payload.
        # @param parent [Object] The object to which requests should be sent.
        # @param object [ModelObject] The object for which this Poster is
        #                             handling a POST.
        # @param default_id [Object] The ID to assign to payloads without a
        #   specific ID.
        def initialize(payload_processor, parent, object)
          super(parent)
          @payload_processor = payload_processor
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
          @payload_processor.process(
            forward: method(:post_forward),
            hash: method(:post_hash),
            url: method(:post_url)
          )
        end

        def post_forward(id, item)
          fail('Not implemented.')
        end

        # Wrapper over new and run
        def self.post(post_payload, default_id, *args)
          pp = Bra::DriverCommon::PayloadProcessor.new(
            post_payload, default_id, method(:forward_if_id)
          )
          new(pp, *args).run
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
