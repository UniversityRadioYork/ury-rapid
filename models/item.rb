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

        valid_type = %i(library file text null).include? type
        raise "Not a valid type: #{type}" unless valid_type

        @type = type
        @name = name
      end

      # Public: Converts the Item to a hash representation.
      #
      # This conversion is not reversible and may lose some information.
      #
      # Returns a hash representation of the Item.
      def to_hash
        { name: @name, type: @type }
      end

      def get_privileges
        []
      end

      def put_do(new_item)
        value = new_item[id] if new_item.is_a?(Hash)
        value = new_item unless new_item.is_a?(Hash)

        if value.is_a?(Hash)
          value = value.symbolize_keys!
          @name = value[:name]
          @type = value[:type]
        elsif value.is_a?(Item)
          @name = value.name
          @type = value.type
        else
          fail("Unsupported argument to put_do: #{value.class}")
        end
      end

      alias_method :to_jsonable, :to_hash
      # The driver_XYZ methods allow the driver to perform modifications to the
      # model using the same verbs as the server without triggering the usual
      # handlers.  They are implemented using the _do methods.
      alias_method :driver_put, :put_do
      alias_method :driver_delete, :delete_do
    end
  end
end
