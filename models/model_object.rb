module Bra
  module Models
    # Internal: An object in the BRA model.
    class ModelObject
      # Public: Allows read access to the object's name.
      attr_reader :name

      def initialize(name)
        @name = name
      end

      # Public: Converts a model object to JSON.
      #
      # This expects a to_hash method to be defined.
      #
      # Returns the JSON representation of the model object.
      def to_json
        to_hash.to_json
      end
    end
  end
end
