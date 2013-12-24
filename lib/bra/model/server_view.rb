require 'bra/common/payload'
require 'bra/model/view'

module Bra
  module Model
    # The server's view of the model
    #
    # This provides the driver with a get/put/post/delete API.
    class ServerView < View
      def get(url)
        find { |object| yield object }
      end

      %i{put post delete}.each do |action|
        define_method(action) do |url, privileges, raw_payload|
          find do |object|
            payload = make_payload(action, privilege_set, request, target)
            object.send(action, payload)
          end
        end
      end

      private

      def make_payload(action, privilege_set, request, target)
        raw_payload = get_raw_payload(request)
        Common::Payload.new(
          raw_payload, privilege_set,
          (action == :put ? target.id : target.default_id)
        )
      end
    end
  end
end
