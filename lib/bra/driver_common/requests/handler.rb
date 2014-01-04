require 'bra/common/exceptions'
require 'bra/driver_common/handler'

module Bra
  module DriverCommon
    module Requests
      # Abstract class for handlers for a given model object
      #
      # Handlers are installed on model objects so that, when the server
      # attempts to modify the model object, the handler translates it into a
      # playout system command to perform the actual playout system event the
      # model change represents.
      class Handler < Bra::DriverCommon::Handler
        extend Forwardable

        def to_s
          self.class.name
        end

        def initialize(parent, action, object, payload)
          super(parent)
          @action  = action
          @object  = object
          @payload = payload
        end

        def run
          self.send(@action)
        end

        def self.use_post_payload_processor
          define_method(:post) { @payload.process(self) }
        end

        def self.put_by_posting_to_parent
          define_method(:put) { @object.post_to_parent(@payload) }
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
        def_delegator(:@parent, :request)

        # Default to a 'not supported' exception on all actions.
        %w{put post delete}.each do |action|
          define_method(action) do |*|
            fail(Bra::Common::Exceptions::NotSupportedByBra)
          end
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
        # @param payload [Payload] A payload (whose value is meaningless, as
        #   this is a DELETE).
        #
        # @return (see #put)
        def delete(variable, payload)
          put(
            variable,
            payload.with_body(variable.id => variable.initial_value)
          )
        end
      end
    end
  end
end
