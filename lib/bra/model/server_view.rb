require 'bra/common/payload'
require 'bra/model/view'

module Bra
  module Model
    # The server's view of the model
    #
    # This provides the driver with a get/put/post/delete API.
    class ServerView < View
      def get(url)
        find(url) { |object| yield object }
      end

      %i(put post delete).each do |action|
        define_method(action) do |url, privilege_set, raw_payload|
          find(url) do |object|
            payload = make_payload(action, privilege_set, raw_payload, object)
            object.send(action, payload)
          end
        end
      end

      private

      def make_payload(action, privilege_set, raw_payload, object)
        Common::Payload.new(
          raw_payload, privilege_set,
          (action == :put ? object.id : object.default_id)
        )
      end
    end
  end
end
