# High-level versions of BAPS commands.
module Commands
  module Codes
    SET_BINARY_MODE = 0xE600
    LOGIN = 0xE800

    SYNC = 0xE303
  end

  class Command
    def run(listener)
    end
  end

  class Initiate < Command
    def run(listener)
      BapsRequest.new(Codes::SET_BINARY_MODE).send(listener.writer)
      listener.register(Responses::System::SEED) do |response, listener|
        p response
        yield response[:seed]
        listener.deregister(response[:command])
      end
    end
  end

  class Authenticate < Command
    module Errors
      OK = 0
      INCORRECT_USER = 1
      EMPTY_USER = 2
      INCORRECT_PASSWORD = 3
    end

    def initialize(username, password, seed)
      @username = username
      @password = password
      @seed = seed
    end

    def run(listener)
      password_hash = Digest::MD5.hexdigest(@password)
      response = Digest::MD5.hexdigest(@seed + password_hash)

      cmd = BapsRequest.new(Codes::LOGIN).string(@username).string(response)
      cmd.send(listener.writer)

      listener.register(Responses::System::LOGIN) do |response, listener|
        yield response[:subcode], response[:details]
        listener.deregister(response[:command])
      end
    end
  end

  class Synchronise < Command
    def run(listener)
      BapsRequest.new(Codes::SYNC).send(listener.writer)
    end
  end

  class Login < Command
    def initialize(username, password)
      @username = username
      @password = password
    end

    def run(listener, &block)
      Initiate.new.run(listener) { |seed| authenticate listener, seed, block }
    end

    def authenticate(listener, seed, post_login_block)
      auth = Authenticate.new(@username, @password, seed)
      auth.run(listener) do |code, string|
        if code == Authenticate::Errors::OK
          Synchronise.new.run(listener)
        end

        post_login_block.call code, string
      end
    end
  end
end
