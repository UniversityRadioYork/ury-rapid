require 'bra/model/view'

module Bra
  module Model
    # The driver's view of the model
    #
    # This provides the driver with a get/put/post/delete API.
    class DriverView < View
      # Gets a model object, given its URL relative to the model root
      def get(url)
        find(url) { |resource| resource }
      end

      %w{put post delete}.each do |action|
        define_method(action) do |url, *args|
          find(url) { |resource| resource.send("driver_#{action}", *args) }
        end
      end
    end
  end
end
