require 'active_support/core_ext/hash/keys'
require_relative 'model_object'

module Bra
  module Models
    # An item in the playout system.
    class Item < SingleModelObject
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
      def initialize(type, name)
        super()

        @type = validate_type(type)
        @name = name
      end

      # Converts the Item to a flat representation
      #
      # This conversion is not reversible and may lose some information.
      #
      # @return [Hash] A flat representation of the Item.
      def flat
        { name: @name, type: @type }
      end

      # PUTs a new item representation into this Item from the driver end
      #
      # The new item may be a hash representation, an existing Item, nil, or a
      # hash mapping this item's ID to one of the above (for compatibility with
      # the external API).
      def driver_put(new_item)
        value = new_item[id] if new_item.is_a?(Hash)
        value = new_item unless new_item.is_a?(Hash)

        done = nil
        done = set_from_hash(value) if value.is_a?(Hash)
        done = set_from_item(value) if value.is_a?(Item)
        done = clear if value.nil?
        fail("Unsupported argument to driver_put: #{value.class}") unless done

        notify_update
      end

      # Performs a DELETE on this object from the driver end
      #
      # @return [void]
      def driver_delete
        # Must notify before changing parent, as the notification requires
        # a valid full URL.
        notify_delete

        parent.remove_child(id)
        @parent = nil
        @id = nil
      end

      # Sets the item's properties from a hash
      #
      # The hash should have keys 'value' and 'type', which may be symbols or
      # strings.
      #
      # @param hash [Hash] The hash containing the values to place in this
      #   Item.
      #
      # @return [Item] This object, for method chaining.
      def set_from_hash(hash)
        # This is to allow the keys to be strings as well as symbols.
        hash = hash.symbolize_keys

        @name = hash[:name]
        @type = validate_type(hash[:type])

        self
      end

      # Sets the item's properties from an existing item
      #
      # @param item [Item] The Item whose values are to be copied into this
      #   Item.
      #
      # @return (see #set_from_hash)
      def set_from_item(item)
        @name = item.name
        @type = validate_type(item.type)

        self
      end

      # Clears the item, setting it to a null item
      #
      # @return (see #set_from_hash)
      def clear
        @name = nil
        @type = :null

        self
      end

      private

      def validate_type(type)
        type = :null if type.nil?
        type = type.intern if type.respond_to?(:intern)
        valid_type = %i(library file text null).include?(type)
        raise "Not a valid type: #{type}" unless valid_type
        type
      end
    end

    # Mixin for model objects that hold Items, such as players and playlists.
    module ItemContainer
      def driver_post(id, resource)
        id == :item ? driver_post_item(id, resource) : super(id, resource)
      end

      # Helper for model object driver_posts instances for adding Items
      def driver_post_item(id, resource)
        ( resource
          .register_update_channel(@update_channel)
          .register_handler(@handler.item_handler(resource))
          .move_to(self, id)
          .notify_update
        )
      end
    end
  end
end
