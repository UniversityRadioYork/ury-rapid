module Rapid
  module ServiceCommon
    # A base class for Rapid services
    #
    # Inheritance of Rapid::ServiceCommon::Service is not required for Service
    # classes, but is recommended.
    #
    # Subclasses must implement the #sub_model_structure method, which takes an
    # update channel and returns the service's sub-model.  The subclass may
    # perform any actions it needs to do on the structure in this method, such
    # as adding model handlers.
    #
    # Subclasses may use the readers #logger and #service_view to get access
    # to their logger and view of the model, respectively.
    class Service
      # Initialises the service
      #
      # @api      semipublic
      # @example  Create a new service
      #   service = Service.new(logger, view, auth)
      #
      # @param logger [Object]
      #   An object that can be used to log messages from the service.
      # @param view [Rapid::Model::ServerView]
      #   A server view of the entire model.
      # @param auth [Object]
      #   An authentication provider.
      def initialize(logger, view, auth)
        @logger = logger
        @view = view
        @auth = auth
      end

      # Asks the service to prepare its sub-model structure
      #
      # This is intended to be called by the Rapid launcher when initialising
      # the services.
      #
      # @api      semipublic
      # @example  Request the sub-model structure of this Service
      #   sub_model, register_view_proc = service.sub_model
      #
      # @param update_channel [Rapid::Model::UpdateChannel]
      #   The update channel that should be used when creating the sub-model
      #   structure.
      #
      # @return [Array]
      #   A triple of the completed sub-model structure, a proc that should
      #   be called with a ServiceView of the completed model, and a proc that
      #   should be called with its ServerView.
      def sub_model(update_channel)
        [sub_model_structure(update_channel),
         method(:service_view=),
         ->(_) {}  # We don't need a server view of our own model.
        ]
      end

      protected

      # Gets this service's logger object
      #
      # @api private
      # @return [Object]
      #   An object that this service can use to log.
      attr_reader :logger

      # Gets this service's server view
      #
      # @api private
      # @return [Rapid::Model::ServerView]
      #   A view that can query and request changes to the entire model.
      attr_reader :view

      # Gets this service's authentication provider
      #
      # @api private
      # @return [Object]
      #   This service's authentication provider.
      attr_reader :auth

      # Gets this service's service view
      #
      # @api private
      # @return [Rapid::Model::ServiceView]
      #   A view that can update this service's portion of the model.
      attr_accessor :service_view
    end
  end
end
