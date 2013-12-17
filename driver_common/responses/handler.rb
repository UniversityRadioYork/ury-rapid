require_relative '../handler'
require_relative '../../exceptions'

module Bra
  module DriverCommon
    module Responses
      # Abstract class for handlers for a given model object
      #
      # Handlers are installed on model objects so that, when the server
      # attempts to modify the model object, the handler translates it into a
      # playout system command to perform the actual playout system event the
      # model change represents.
      class Handler < Bra::DriverCommon::Handler
        extend Forwardable

        def initialize(parent)
          super(parent)
          @model = parent.model
        end

        # Shorthand for @model.driver_X_url.
        def_delegator(:@model, :find_url, :find)
        %i{put post delete}.each do |action|
          def_delegator(:@model, "driver_#{action}_url".intern, action)
        end

        # Like delete, but does not fail if the resource does not exist.
        def delete_if_exists(*args)
          delete(*args)
        rescue Bra::Exceptions::MissingResourceError
          nil
        end
      end
    end
  end
end
