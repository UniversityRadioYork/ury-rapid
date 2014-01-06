require 'eventmachine'

module Bra
  module Model
    # Mixin for classes that use an UpdateChannel
    module Updatable
      extend Forwardable

      # Registers an update channel for this object
      #
      # @param channel [UpdateChannel] A channel to which objects interested in
      #   this object's updates can subscribe.  The same channel may (and
      #   usually will) be shared between multiple objects; the payloads
      #   sent to the channel will uniquely identify the object in question.
      #
      # @return [self]
      def register_update_channel(channel)
        @update_channel = channel
        self
      end

      def notify_update
        @update_channel.notify_update(self)
      end

      def notify_delete
        @update_channel.notify_delete(self)
      end

      def register_for_updates(&block)
        @update_channel.register_for_updates(&block)
      end

      def deregister_from_updates(id)
        @update_channel.deregister_from_updates(id)
      end
    end

    # An update channel
    #
    # By default, the update channel sends to a newly constructed, internal
    # EventMachine Channel; this can be changed.
    class UpdateChannel
      extend Forwardable

      def initialize(em_channel = nil)
        @em_channel = em_channel || EventMachine::Channel.new
      end

      def notify_update(object)
        notify(object, object.flat)
      end

      def notify_delete(object)
        notify(object, nil)
      end

      def_delegator :@em_channel, :subscribe, :register_for_updates
      def_delegator :@em_channel, :unsubscribe, :deregister_from_updates

      private

      def notify(object, repr)
        push([object, repr])
      end

      def_delegator :@em_channel, :push
    end
  end
end
