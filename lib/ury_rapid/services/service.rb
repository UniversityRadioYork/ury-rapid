module Rapid
  module Services
    # A base class for Rapid services
    #
    # Inheritance of Rapid::Services::Service is not required for Service
    # classes, but is recommended.
    #
    # Subclasses must implement the #sub_model_structure method, which takes an
    # update channel and returns the service's sub-model.  The subclass may
    # perform any actions it needs to do on the structure in this method, such
    # as adding model handlers.
    #
    # Subclasses may use the readers #logger and #view to get access
    # to their logger and view of the model, respectively.
    class Service
      # Initialises the service
      #
      # @api      semipublic
      # @example  Create a new service
      #   service = Service.new(logger, view, auth)
      #
      # @param view [Rapid::Model::View]
      #   A View of the model, with direct access to this Service's part of the
      #   model.
      def initialize(view)
        @view = view
      end

      protected

      # Gets this service's view
      #
      # @api private
      # @return [Rapid::Model::View]
      #   A view that can query the entire model, and update this service's
      #   sub-model.
      attr_reader :view
    end
  end
end
