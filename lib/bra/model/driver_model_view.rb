require 'bra/model/finder'

module Bra
  module Model
    # The driver's view of the model
    #
    # This provides the driver with a get/put/post/delete API
    class DriverModelView
      # Initialises the model view
      #
      # @param root [Root]  The model root.
      def initialize(model)
        @root = model
      end

      # Gets a model object, given its URL relative to the model root
      def get(url)
        find(url) { |resource| resource }
      end

      %w{put post delete}.each do |action|
        define_method(action) do |url, *args|
          find(url) { |resource| resource.send("driver_#{action}", *args) }
        end
      end

      private

      def find(url, &block)
        Finder.find(@root, url, &block)
      end
    end
  end
end
