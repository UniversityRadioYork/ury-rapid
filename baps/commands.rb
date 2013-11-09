require 'digest'
require_relative 'request'

module Bra
  module Baps
    # High-level versions of BAPS commands
    #
    # These command classes are intended to be composable and accessible by
    # clients, but translate down into native BAPS command phrases.
    module Commands
      # Class for errors caused while handling command parameters
      class ParamError < RuntimeError
      end

      # The base class for all Command types
      class Command
        # Dummy Run command
        #
        # @param _ [Object] Ignored.
        #
        # @return [void]
        def run(_)
        end
      end

      # A command that operates upon a channel.
      class ChannelCommand < Command
        # Initialises a ChannelCommand.
        #
        # channel - The Channel ID.
        #
        def initialize(channel)
          @channel = channel
        end
      end

      # A command that clears the playlist of a channel.
      class ClearPlaylist < ChannelCommand
        # Runs a ClearPlaylist command on the given requests queue.
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

      # A command that sets the current playback status of a channel.
      class SetPlayerState < ChannelCommand
        ##
        # Initialises a SetPlayerState command.
        #
        # 'from' and 'to' should be the current and desired states of
        # 'channel', as strings or symbols.
        #
        # channel - The ID of the channel, as an integer or any coercible type.
        #
        # state   - The state (one of :stopped, :paused or :playing); can be a
        #           string equivalent.
        def initialize(channel, from, to)
          super channel

          # Convert these to symbols, if they are currently strings.
          from = from.intern
          to = to.intern

          [from, to].each do |sym|
            valid_state = %i(stopped paused playing).include?(sym)
            fail(ParamError, 'Not a valid state') unless valid_state
          end

          @command = CODES[from][to]
        end

        # Creates a new SetPlayerState, populating the channel ID and
        # from-state from a player state model object.
        #
        # @return [SetPlayerState] The constructed command.
        def self.from_model(object, to)
          new(object.player_channel_id, object.value, to)
        end

        # Runs a SetPlayerState command on the given requests queue.
        #
        # As this command has no direct return value, it does not need a
        # dispatch.
        #
        # queue - The requests queue to which the BAPS equivalent of this
        #         command should be sent.
        #
        # @return [Boolean] false (for use in handlers).
        def run(queue)
          Request.new(@command, @channel).to(queue) unless @command.nil?
          false
        end

        def self.to_delete_handler(queue)
          ->(object) { from_model(object, object.initial_value).run(queue) }
        end

        def self.to_put_handler(queue)
          # BAPS is rather interesting in how it interprets the
          # play/pause/stop commands:
          #
          # - PLAY will play the song if it's stopped, or *restart* the song if
          #   it's paused;
          # - PAUSE will pause the song if it's playing or if it's stopped, but
          #   *play* the song if it's paused;
          # - STOP is fine, it stops and doesn't afraid of anything.
          #
          # This is at odds with how BRA sees things, so we can't just map the
          # states down to their "obvious" commands!
          ->(object, new_state) { from_model(object, new_state).run(queue) }
        end

        private

        # Mapping between state symbols and BAPS request codes.
        CODES = {
          playing: {
            playing: nil,
            paused: Codes::Playback::PAUSE,
            stopped: Codes::Playback::STOP
          },
          paused: {
            # The below is not a typo, it's how BAPS works...
            playing: Codes::Playback::PAUSE,
            paused: nil,
            stopped: Codes::Playback::STOP
          },
          stopped: {
            # BAPS allows us to pause while the song is stopped.  This makes
            # little sense, and bra disallows it, so we ignore it.
            playing: Codes::Playback::PLAY,
            paused: nil,
            stopped: nil
          }
        }
      end

      # A command that sets the current playback position of a channel.
      class SetPlayerPosition < ChannelCommand
        # Initialises a SetPlayerPosition command.
        #
        # channel - The ID of the channel, as an integer or any coercible type.
        # position - The new position, as an integer or any coercible type.
        def initialize(channel, position)
          super(channel)
          @position = Integer(position)
        end

        # Runs a SetPlayerPosition command on the given requests queue.
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

      # A command that initiates communication with the BAPS server.
      #
      # This command is safe to use publicly, but consider using the Login
      # command instead.
      class Initiate < Command
        # Sends an Initiate command to the given queue.
        #
        # queue - The requests queue to which the BAPS equivalent of this
        #         command should be sent.
        #
        # Returns nothing.
        def run(queue)
          Request.new(Codes::System::SET_BINARY_MODE).to(queue)
        end
      end

      # A command that authenticates to the BAPS server.
      #
      # This command is safe to use publicly, but consider using the Login
      # command instead.
      class Authenticate < Command
        # Error codes returned by the BAPS server upon authentication.
        module Errors
          OK = 0
          INCORRECT_USER = 1
          EMPTY_USER = 2
          INCORRECT_PASSWORD = 3
        end

        # Initialise an Authenticate command.
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

        # Runs an Authenticate command on the given dispatcher.
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

      # Sets the BAPS server to send broadcast messages, as well as
      # making it forward the current server state to us.
      #
      # This command is safe to use publicly, but consider using the Login
      # command instead.
      class Synchronise < Command
        # Runs a Synchronise command on the given dispatcher.
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
          player_state_put: SetPlayerState.to_put_handler(queue),
          player_state_delete: SetPlayerState.to_delete_handler(queue)
        }
      end
    end
  end
end
