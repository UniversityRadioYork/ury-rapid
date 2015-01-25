require 'eventmachine'

module Rapid
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
        @update_channel = channel || NoUpdateChannel.new
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

    # Abstract base class for update channels
    #
    # You probably want EmUpdateChannel or DummyUpdateChannel instead.
    class UpdateChannel
      def notify_update(object)
        notify(object, object.flat)
      end

      def notify_delete(object)
        notify(object, nil)
      end
    end

    # A null object signifying an absence of update channel
    #
    # This sends an error on any attempt to use an update channel.
    # If an update channel that works, but ignores any updates, is wanted, use
    # DummyUpdateChannel.
    class NoUpdateChannel < UpdateChannel
      def notify(object, _repr)
        puts("No update channel assigned to updating object #{object}")
      end
    end

    # An update channel that ignores all updates and registrations
    #
    # Not to be confused with NoUpdateChannel, which fires an error on any
    # attempt to use the event channel.
    class DummyUpdateChannel < UpdateChannel
      private

      # Does nothing.
      def nop(*_)
      end

      public

      alias_method :notify, :nop
      alias_method :register_for_updates, :nop
      alias_method :deregister_from_updates, :nop
    end

    # An EventMachine-based update channel
    #
    # By default, the update channel sends to a newly constructed, internal
    # EventMachine Channel; this can be changed.
    class EmUpdateChannel < UpdateChannel
      extend Forwardable

      delegate %i(subscribe
                  unsubscribe
                  register_for_updates
                  deregister_from_updates) => :em_channel

      def initialize(in_em_channel = nil)
        super()
        @em_channel = in_em_channel || EventMachine::Channel.new
      end

      private

      attr_reader :em_channel

      delegate %i(push) => :em_channel

      def notify(object, repr)
        push([object, repr])
      end
    end
  end
end
