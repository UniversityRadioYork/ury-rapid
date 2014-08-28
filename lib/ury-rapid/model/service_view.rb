require 'forwardable'
require 'ury-rapid/model/view'

module Rapid
  module Model
    # The service's view of the model
    #
    # This provides the service with a get/put/post/delete API.
    class ServiceView < View
      extend Forwardable

      def initialize(model, structure)
        super(model)

        @structure = structure
      end

      # Gets a model object, given its URL relative to the model root
      def get(url)
        find(url) { |resource| resource }
      end

      %w(put post delete).each do |action|
        define_method(action) do |url, *args|
          find(url) { |resource| resource.send("service_#{action}", *args) }
        end
      end

      def_delegator :@structure, :register
      def_delegator :@structure, :create_model_object
    end
  end
end