require 'active_support/core_ext/hash/keys'
require 'compo'

require 'bra/common/types'
require 'bra/model/model_object'

module Bra
  module Model
    # An item in the playout system.
    class Item < Compo::Branches::Leaf
      include Bra::Common::Types::Validators
      include ModelObject

      attr_reader :name

      # Access the track type.
      attr_reader :type

      # Creates a new Item
      #
      # @api semipublic
      #
      # @example Create a library track item.
      #   Item.new(:library, 'Islands In The Stream'
      #
      # @param type [Symbol] The Item type: one of :library, :file or :text.
      # @param name [String] The display name of the Item.
      # @param origin [String] The origin of the Item, as an URL or
      #   pseudo-URL, if available.
      # @param duration [Integer] The duration of the Item, in milliseconds.
      def initialize(type, name, origin, duration)
        super()

        @type = type
        @name = name
        @origin = origin
        @duration = duration
      end

      # Converts the Item to a flat representation
      #
      # This conversion is not reversible and may lose some information.
      #
      # @return [Hash] A flat representation of the Item.
      def flat
        { name: @name, type: @type, origin: @origin, duration: @duration }
      end

      # PUTs a new item representation into this Item from the service end
      #
      # This just asks the parent to POST the new item over this one, for the
      # sake of convenience.
      #
      # @param new_item [Item] The new Item.
      def service_put(new_item)
        parent.service_post(id, new_item)
      end

      # Performs a DELETE on this object from the service end
      #
      # @return [void]
      def service_delete
        # Must notify before changing parent, as the notification requires
        # a valid full URL.
        notify_delete
        move_to(nil, nil)
      end
    end

    # Mixin for model objects that hold Items, such as players and playlists.
    module ItemContainer
    end
  end
end
