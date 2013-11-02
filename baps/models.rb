require_relative '../models/model_object'

module Bra
  module Baps
    # Internal: Model objects specific to BAPS.
    # 
    # The BAPS module exposes its own custom model tree in the x-baps/ section
    # of BRA's URL hierarchy, containing information specific to the BAPS
    # playout system.
    module Models
      # Internal: The parent model object for model objects in the BAPS
      # namespace.
      class XBaps < Bra::Models::HashModelObject
        def get_privileges()
          [:XBapsReadConfig]
        end
      end

      # Internal: The model object containing server information for BAPS.
      class Server < Bra::Models::HashModelObject
        def get_privileges()
          [:XBapsReadConfig]
        end
      end

      # Internal: A model object containing a constant value.
      class Constant < Bra::Models::SingleModelObject
        attr_reader :value

        # Internal: Initialise the Constant object.
        # 
        # value - The value of the constant.
        def initialize(value, privileges)
          @value = value
          @privileges = privileges
        end

        # Internal: Returns a flat represention of the object.
        def to_jsonable()
          value
        end

        def to_s()
          value.to_s
        end

        def get_privileges()
          @privileges
        end
      end

      # Internal: Constructs and populates the BAPS model set under the given
      # model root.
      # 
      # The BAPS models are initially populated with values from the config given.
      #
      # model  - The root of the model to which the BAPS model tree should be
      #          added.
      # config - The config dict from which the BAPS model will be populated.
      #
      # Returns the resulting model; the input model may be mutated.
      def self.add_baps_models_to(model, config)
         xbaps = XBaps.new.move_to(model, :x_baps)
         server = Server.new.move_to(xbaps, :server)
         config.each do |key, value|
           Constant.new(value, [:XBapsReadConfig]).move_to(server, key)
         end

         model
      end
    end
  end
end
