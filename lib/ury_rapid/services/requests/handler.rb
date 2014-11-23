require 'ury_rapid/common/exceptions'
require 'ury_rapid/services/handler'

module Rapid
  module Services
    module Requests
      # Abstract class for handlers for a given model object
      #
      # Handlers are installed on model objects so that, when the server
      # attempts to modify the model object, the handler translates it into a
      # playout system command to perform the actual playout system event the
      # model change represents.
      class Handler < Rapid::Services::Handler
        extend Forwardable

        HOOKS = {}

        def to_s
          self.class.name
        end

        def initialize(in_parent, in_action, in_object, in_payload)
          super(in_parent)
          @action  = in_action
          @object  = in_object
          @payload = in_payload
        end

        def run
          send(action)
        end

        # Requests that a DELETE on this handler be sent to the item's children
        def self.delete_by_deleting_children
          class_eval do
            def delete
              object.children.each { |_, child| child.delete(@payload) }
            end
          end
        end

        def self.use_payload_processor_for(action, *ids)
          add_id_hook(action, ids) do |handler, _object, payload|
            payload.process(handler)
          end
        end

        def self.post_by_putting_to_child_for(*ids)
          add_id_hook(:post, ids) do |_handler, object, payload|
            object.get_child(payload.id).put(payload)
          end
        end

        def self.put_by_payload_processor
          add_hook(:put) do |handler, _object, payload|
            payload.process(handler)
          end
        end

        def self.put_by_posting_to_parent
          add_hook(:put) do |_handler, object, payload|
            object.post_to_parent(payload)
          end
        end

        def self.add_id_hook(action, ids)
          add_hook(action) do |handler, object, payload|
            active = ids.empty? || ids.include?(payload.id)
            yield(handler, object, payload) if active
            active
          end
        end

        def self.add_hook(action, &block)
          HOOKS[action] = [] unless HOOKS.key?(action)
          HOOKS[action] << block
        end

        def self.on_delete(&block)
          define_method(:delete) { instance_exec(&block) }
        end

        # Generates NotSupportedByService stubs for the given methods
        def self.service_should_override(*methods)
          methods.each do |method|
            define_method(method) do |*_args|
              fail(Rapid::Common::Exceptions::NotSupportedByService)
            end
          end
        end

        protected

        attr_reader :action
        attr_reader :object
        attr_reader :parent
        attr_reader :payload

        def_delegator :object, :id, :caller_id
        def_delegator :object, :parent_id, :caller_parent_id
        def_delegator :object, :parent, :caller_parent
        def_delegator :payload, :id, :payload_id

        delegate %i(request) => :parent

        # Default to a 'not supported' exception on all actions.
        %i(put post delete).each do |a|
          define_method(a) do |*|
            run_hooks(a) || fail(Rapid::Common::Exceptions::NotSupportedByRapid)
          end
        end

        def run_hooks(action)
          HOOKS.fetch(action, []).any? { |b| b.call(self, object, payload) }
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
          put(variable,
              payload.with_body(variable.id => variable.initial_value))
        end
      end
    end
  end
end
