module Bra
  module Model
    # Public: A model of the BAPS server state.
    class Root < HashModelObject
      # Returns the canonical URL of the model channel list
      #
      # @return [String] the URL, relative to the API root.

      def parent_url
        fail('Tried to get parent URL of the model root.')
      end

      def id
        ''
      end

      alias_method :url, :id
    end
  end
end
