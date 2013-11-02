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

        valid_type = %i(library file text).include? type
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

      alias_method :to_jsonable, :to_hash
    end
  end
end
