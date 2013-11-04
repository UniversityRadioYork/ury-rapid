require 'active_support/core_ext/hash/keys'
require_relative 'model_object'

module Bra
  module Models
    # Public: An item in the playout system.
    class Item < SingleModelObject
      alias_method :enqueue, :move_to

      attr_reader :name

      # Public: Access the track type.
      attr_reader :type

      def initialize(type, name)
        super()

        @type = validate_type(type)
        @name = name
      end

      def validate_type(type)
        type = :null if type.nil?
        type = type.intern if type.respond_to?(:intern)
        valid_type = %i(library file text null).include? type
        raise "Not a valid type: #{type}" unless valid_type
        type
      end

      # Public: Converts the Item to a hash representation.
      #
      # This conversion is not reversible and may lose some information.
      #
      # Returns a hash representation of the Item.
      def flat
        { name: @name, type: @type }
      end

      def get_privileges
        []
      end

      # PUTs a new item representation into this Item without triggering
      # handlers.
      #
      # The new item may be a hash representation, an existing Item, nil, or a
      # hash mapping this item's ID to one of the above (for compatibility with
      # the external API).
      def put_do(new_item)
        value = new_item[id] if new_item.is_a?(Hash)
        value = new_item unless new_item.is_a?(Hash)

        done = nil
        done = put_from_hash(value) if value.is_a?(Hash)
        done = set_from_item(value) if value.is_a?(Item)
        done = clear if value.nil?
        fail("Unsupported argument to put_do: #{value.class}") unless done
      end

      # Sets the item's properties from a hash.
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

      # Sets the item's properties from an existing item.
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

      ##
      # Clears the item, setting it to a null item.
      #
      # @return (see #set_from_hash)
      def clear
        @name = nil
        @type = :null

        self
      end

      # The driver_XYZ methods allow the driver to perform modifications to the
      # model using the same verbs as the server without triggering the usual
      # handlers.  They are implemented using the _do methods.
      alias_method :driver_put, :put_do
      alias_method :driver_delete, :delete_do
    end
  end
end
