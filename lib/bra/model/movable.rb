module Bra
  module Model
    # Mixin for objects that can be moved into other objects
    module Movable
      # Updates this object's parent and ID function
      #
      # @api semipublic
      # @example  Update this Movable's parent and ID function.
      #   movable.update_parent(new_parent, new_id_function)
      # @example  Set this Movable to have no parent.
      #   movable.update_parent(nil, nil)
      def update_parent(new_parent, new_id_function)
        @parent = new_parent
        @id_function = new_id_function || null_id_function
      end

      def null_id_function
        ->{ nil }
      end

      # Moves this model object to a new parent with a new ID.
      #
      # @param new_parent [ModelObject] The new parent for this object (can be
      #   nil).
      # @param new_id [Object]  The new ID under which the object will exist in
      #   the parent.
      #
      # @return [self]
      def move_to(new_parent, new_id)
        move_from_old_parent
        move_to_new_parent(new_parent, new_id)
        self
      end

      private

      # Performs the move from an old parent, if necessary
      def move_from_old_parent
        @parent.remove_child(id) unless @parent.nil?
      end

      # Performs the move to a new parent, if necessary
      def move_to_new_parent(new_parent, new_id)
        new_parent.add_child(new_id, self) unless new_parent.nil?
      end
    end
  end
end
