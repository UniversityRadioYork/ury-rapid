require 'sinatra/base'
require 'sinatra/contrib'
require 'sinatra/streaming'

require 'ury_rapid/common/payload'

require 'ury_rapid/server/helpers'
require 'ury_rapid/server/routing'
require 'ury_rapid/server'

require 'kankri'

module Rapid
  module Server
    # The Sinatra application that powers the server component of Rapid
    #
    # Much of the functionality of the Sinatra app is held in separate helper
    # and routing modules.  See Rapid::Server::Helpers and
    # Rapid::Server::Routing.
    class App < Sinatra::Base
      def initialize(config, environment)
        super()

        fail(ArgumentError, 'Need an environment.') if environment.nil?

        @environment = environment
        @config      = config

        rd_key = :root_directory
        settings.set :root, config[rd_key] if config.key?(rd_key)
      end

      attr_reader :environment

      #
      # Configuration
      #

      configure do
        # Make sure requests are taken on the reactor thread.
        set :threaded, false
      end

      register Sinatra::Contrib
      use Rack::MethodOverride

      respond_to :html, :json, :xml

      #
      # Helpers
      #

      helpers Sinatra::Streaming

      helpers Helpers::Auth
      helpers Helpers::Error
      helpers Helpers::Files
      helpers Helpers::Inspector
      helpers Helpers::Model
      helpers Helpers::Streaming

      #
      # Routing
      #

      register Routing::Files
      register Routing::Streaming

      # The model routes need to be at the bottom, so that they don't override
      # more specific URL matches.
      register Routing::Model
    end
  end
end
