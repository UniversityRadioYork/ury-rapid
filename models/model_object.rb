module Bra
  module Models
    # Internal: An object in the BRA model.
    class ModelObject
      # Public: Allows read access to the object's name.
      attr_reader :name

      # Public: Allows read access to the object's short name.
      attr_reader :short_name

      def initialize(name, short_name=nil)
        short_name ||= name

        @name = name
        @short_name = short_name
      end

      # Public: Converts a model object to compact JSON.
      #
      # This expects a to_jsonable method to be defined.
      #
      # Returns the JSON representation of the model object.
      def to_json(*args)
        to_jsonable.to_json(*args)
      end

      # Public: Converts a model object to a format that can be rendered to
      # JSON.
      #
      # Unless overridden, this expects a to_hash method to be defined.
      #
      # Returns a representation of the model object that can be converted to
      # JSON.
      def to_jsonable
        to_hash
      end
    end
  end
end
