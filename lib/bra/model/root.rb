module Bra
  module Model
    # The root of the bra model
    #
    # The Root contains every other object in the bra model.  It has no parent,
    # and its id and URL are both defined as the empty string.
    class Root < HashModelObject
      # Fails, because the model root does not have a parent
      #
      # @api public
      # @example  Attempt, in vain, to get the parent URL of the model root.
      #   root.parent_url
      #
      # @return [void]
      def parent_url
        fail('Tried to get parent URL of the model root.')
      end

      # Returns the ID of the model root
      #
      # This is the empty string.
      #
      # @api public
      # @example  Getting the ID of the model root.
      #   root.id
      #   #=> ''
      #
      # @return [String]  The empty string.
      def id
        ''
      end

      # Returns the ID of the model root
      #
      # This is the empty string, to allow the normal definition of #url to
      # terminate at the model root and URLs of root children to take the form
      # /child_id.
      #
      # @api public
      # @example  Getting the URL of the model root.
      #   root.url
      #   #=> ''
      #
      # @return [String]  The empty string.
      alias_method :url, :id
    end
  end
end
