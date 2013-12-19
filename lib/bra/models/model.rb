require 'bra/models/item'
require 'bra/models/model_object'
require 'bra/models/player'

module Bra
  module Models
    # Public: A model of the BAPS server state.
    class Root < HashModelObject
      # Returns the canonical URL of the model channel list
      #
      # @return [String] the URL, relative to the API root.
      def url
        id
      end

      def parent_url
        fail('Tried to get parent URL of the model root.')
      end

      def id
        ''
      end
    end
  end
end
