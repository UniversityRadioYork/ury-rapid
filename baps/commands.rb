require 'digest'
require_relative 'request'

module Bra
  module Baps
    # Public: High-level versions of BAPS commands.
    #
    # These command classes are intended to be composable and accessible by
    # clients, but translate down into native BAPS command phrases.
    module Commands
      # Public: Class for errors caused while handling command parameters.
      class ParamError < RuntimeError
      end

      # Internal: The base class for all Command types.
      class Command
        # Internal: Dummy Run command.
        #
        # _ - Ignored.
        #
        # Returns nothing.
        def run(_)
        end
      end

      # Public: A command that operates upon a channel.
      class ChannelCommand < Command
        # Internal: Initialises a ChannelCommand.
        #
        # channel - The Channel object.
        #
        def initialize(channel)
          @channel = channel.id
        end
      end

      # Public: A command that clears the playlist of a channel.
      class ClearPlaylist < ChannelCommand
        # Public: Runs a ClearPlaylist command on the given requests queue.
        #
        # As this command has no direct return value, it does not need a
        # dispatch.
        #
        # queue - The requests queue to which the BAPS equivalent of this
        #         command should be sent.
        #
        # Returns false (for usage as a model method handler).
        def run(queue)
          Request.new(Codes::Playlist::RESET, @channel).to(queue)
          false
        end

        def self.to_channel_delete_handler(queue)
          ->(resource) { new(resource).run(queue) }
        end

        def self.to_player_delete_handler(queue)
          ->(resource) { new(resource.player_channel).run(queue) }
        end

        def self.to_channel_set_delete_handler(queue)
          lambda do |resource|
            resource.channels.each { |channel| new(channel).run(queue) }
          end
        end
      end

      # Public: A command that sets the current playback status of a channel.
      class SetPlayerState < ChannelCommand
        # Public: Initialises a SetPlayerState command.
        #
        # channel - The ID of the channel, as an integer or any coercible type.
        # state   - The state (one of :stopped, :paused or :playing); can be a
        #           string equivalent.
        def initialize(channel, state)
          super channel

          state_symbol = state.is_a?(Symbol) ? state : state.to_sym
          valid_state = %i(stopped paused playing).include?(state_symbol)
          fail(ParamError, 'Not a valid state') unless valid_state

          @state = state_symbol
        end

        # Public: Runs a SetPlayerState command on the given requests queue.
        #
        # As this command has no direct return value, it does not need a
        # dispatch.
        #
        # queue - The requests queue to which the BAPS equivalent of this
        #         command should be sent.
        #
        # Returns nothing.
        def run(queue)
          Request.new(CODES[@state], @channel).to(queue)
        end

        def self.to_put_handler(queue)
          proc do |resource, value|
            new(resource.player_channel, value).run(queue)
            # Let the model object know it cannot update itself directly.
            false
          end
        end

        private

        # Internal: Mapping between state symbols and BAPS request codes.
        CODES = {
          playing: Codes::Playback::PLAY,
          paused: Codes::Playback::PAUSE,
          stopped: Codes::Playback::STOP
        }
      end

      # Public: A command that sets the current playback position of a channel.
      class SetPlayerPosition < ChannelCommand
        # Public: Initialises a SetPlayerPosition command.
        #
        # channel - The ID of the channel, as an integer or any coercible type.
        # position - The new position, as an integer or any coercible type.
        def initialize(channel, position)
          super(channel)
          @position = Integer(position)
        end

        # Public: Runs a SetPlayerPosition command on the given requests queue.
        #
        # As this command has no direct return value, it does not need a
        # dispatch.
        #
        # queue - The requests queue to which the BAPS equivalent of this
        #         command should be sent.
        #
        # Returns nothing.
        def run(queue)
          command = Request.new(Codes::Playback::POSITION, @channel)
          command.uint32(@position).to(queue)
        end
      end

      # Public: A command that initiates communication with the BAPS server.
      #
      # This command is safe to use publicly, but consider using the Login
      # command instead.
      class Initiate < Command
        # Public: Sends an Initiate command to the given queue.
        #
        # queue - The requests queue to which the BAPS equivalent of this
        #         command should be sent.
        #
        # Returns nothing.
        def run(queue)
          Request.new(Codes::System::SET_BINARY_MODE).to(queue)
        end
      end

      # Public: A command that authenticates to the BAPS server.
      #
      # This command is safe to use publicly, but consider using the Login
      # command instead.
      class Authenticate < Command
        # Public: Error codes returned by the BAPS server upon authentication.
        module Errors
          OK = 0
          INCORRECT_USER = 1
          EMPTY_USER = 2
          INCORRECT_PASSWORD = 3
        end

        # Public: Initialise an Authenticate command.
        #
        # username - The password to use to authenticate to the BAPS server.
        # password - The (plaintext) password to use to authenticate to the
        #            BAPS server.
        # seed     - The session seed yielded by a previous Initiate command.
        def initialize(username, password, seed)
          @username = username.to_s
          @password = password.to_s
          @seed = seed
        end

        # Public: Runs an Authenticate command on the given dispatcher.
        #
        # queue - The requests queue to which the BAPS equivalent of this
        #         command should be sent.
        #
        # Returns nothing.
        def run(queue)
          password_hash = Digest::MD5.hexdigest(@password)
          full_hash = Digest::MD5.hexdigest(@seed + password_hash)

          cmd = Request.new(Codes::System::LOGIN)
          cmd.string(@username).string(full_hash).to(queue)
        end
      end

      # Public: Sets the BAPS server to send broadcast messages, as well as
      # making it forward the current server state to us.
      #
      # This command is safe to use publicly, but consider using the Login
      # command instead.
      class Synchronise < Command
        # Public: Runs a Synchronise command on the given dispatcher.
        #
        # This command takes no blocks, but will generate a very high number of
        # requests from the server.
        #
        # queue - The queue to which requests should be sent.
        #
        # Returns nothing.
        def run(queue)
          # Subcode 3: Synchronise and add to chat
          Request.new(Codes::System::SYNC, 3).to(queue)
        end
      end

      def self.handlers(queue)
        {
          channels_delete: ClearPlaylist.to_channel_set_delete_handler(queue),
          player_state_put: SetPlayerState.to_put_handler(queue)
        }
      end
    end
  end
end
