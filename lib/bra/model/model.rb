require 'bra/model/item'
require 'bra/model/model_object'
require 'bra/model/player'

module Bra
  module Model
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
