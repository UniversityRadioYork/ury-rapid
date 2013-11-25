require 'active_support/core_ext/object/try'
require_relative '../utils/hash'
require_relative 'privilege_set'

module Bra
  module Common
    # An object that takes in BRA configuration and authenticates users
    class ConfigAuthenticator
      def initialize(users)
        @users = users

        # Pre-calculate and store the password and privilege sets.
        @passwords = passwords
        @privilege_sets = privilege_sets
      end

      def authenticate(username, password)
        auth_ok?(username, password) ? privileges_for(username) : auth_fail
      end

      private

      def privileges_for(username)
        @privilege_sets[username.intern]
      end

      # Creates a hash mapping username symbols to their password symbols
      def passwords
        @users.transform_values(&method(:to_password))
      end

      def to_password(user)
        user[:password].intern
      end

      # Creates a hash mapping username symbols to their privilege sets
      def privilege_sets
        @users.transform_values(&method(:to_privilege_set))
      end

      def to_privilege_set(user)
        PrivilegeSet.new(user[:privileges])
      end

      def auth_fail
        fail('Authentication failure.')
      end

      def auth_ok?(username, password)
        PasswordCheck.new(username, password, @passwords).ok?
      end
    end

    # A method object that represents a check on username/password pairs
    class PasswordCheck
      def initialize(username, password, passwords)
        @username = username.try(:intern)
        @password = password.try(:intern)
        @passwords = passwords
      end

      def ok?
        auth_present? && password_match?
      end

      def auth_present?
        username_present? && password_present?
      end

      def username_present?
        !(@username.nil? || @username.empty?)
      end

      def password_present?
        !(@password.nil? || @password.empty?)
      end

      def password_match?
        @passwords[@username] == @password
      end
    end
  end
end
