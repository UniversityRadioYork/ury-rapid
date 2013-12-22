require 'active_support/core_ext/hash/keys'

require 'bra/common/exceptions'
require 'bra/common/hash'

module Bra
  module Common
    # Wrapper around a set of privileges a client has
    class PrivilegeSet
      # Initialises a privilege set.
      #
      # @api public
      # @example Create a privilege set with no privileges.
      #   PrivilegeSet.new({})
      # @example Create a privilege set with some privileges.
      #   PrivilegeSet.new({channel_set: [:get, :put]})
      # @example Create a privilege set with all privileges.
      #   PrivilegeSet.new(:god_mode)
      def initialize(privileges)
        @privileges = privileges
        symbolise_privileges
      end

      # Requires a certain privilege on a certain target
      def require(target, privilege)
        fail(
          Bra::Common::Exceptions::InsufficientPrivilegeError
        ) unless has?(target, privilege)
      end

      # Checks to see if a certain privilege exists on a given target
      #
      # @api public
      # @example Check your privilege.
      #   privs.has?(:channel, :put)
      #   #=> false
      #
      # @param target [Symbol] The handler target the privilege is for.
      # @param privilege [Symbol] The privilege (one of :get, :put, :post or
      #   :delete).
      #
      # @return [Boolean] true if the privileges are sufficient; false
      #   otherwise.
      def has?(privilege, target)
        PrivilegeChecker.new(target, privilege, @privileges).check?
      end

      private

      def symbolise_privileges
        @privileges = (
          @privileges
          .deep_symbolize_keys
          .transform_values(&method(:symbolise_privilege_list))
        )
      end

      def symbolise_privilege_list(privlist)
        privlist.is_a?(Array) ? privlist.map(&:to_sym) : privlist.to_sym
      end
    end

    # A method object for checking privileges.
    class PrivilegeChecker
      def initialize(target, requisite, privileges)
        @target = target.intern
        @requisite = requisite.intern
        @privileges = privileges
      end

      def check?
        god_mode? || has_all? || has_direct?
      end

      private

      # @return [Boolean] true if this privilege set has God Mode.
      def god_mode?
        @privileges == :god_mode
      end

      # @return [Boolean] true if this privilege set has all privileges for a
      #   target.
      def has_all?
        @privileges[@target] == :all
      end

      # @return [Boolean] true if this privilege set explicitly has a certain
      #   privilege for a certain target.
      def has_direct?
        target_in_privileges? && requisite_in_target_privileges?
      end

      def target_in_privileges?
        @privileges.key?(@target)
      end

      def requisite_in_target_privileges?
        @privileges[@target].include?(@requisite)
      end
    end
  end
end
