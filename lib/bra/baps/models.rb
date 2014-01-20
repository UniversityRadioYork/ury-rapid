require 'bra/model/structures/playout_model'

module Bra
  module Baps
    # Model objects specific to BAPS
    #
    # The BAPS module exposes its own custom model tree in the x-baps/ section
    # of BRA's URL hierarchy, containing information specific to the BAPS
    # playout system.
    module Model
      # Object that creates the BAPS model set, given a model root and config.
      class Creator < Bra::Model::Structures::PlayoutModel
        def initialize(model_config, baps_config)
          super(model_config)
          @baps_config = baps_config
        end

        def playout_extensions
          log :log

          hash :x_baps, :x_baps do
            hash :server, :x_baps_server do
              constants @baps_config, :x_baps_server_constant
            end
          end
        end
      end
    end
  end
end
