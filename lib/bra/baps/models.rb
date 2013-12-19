require 'bra/models/set'
require 'bra/models/variable'

module Bra
  module Baps
    # Model objects specific to BAPS.
    #
    # The BAPS module exposes its own custom model tree in the x-baps/ section
    # of BRA's URL hierarchy, containing information specific to the BAPS
    # playout system.
    module Models
      # Object that creates the BAPS model set, given a model root and config.
      class Creator < Bra::Models::Creator
        def initialize(model_config, baps_config)
          super(model_config)
          @baps_config = baps_config
        end

        def extend(model)
          root model do
            set :x_baps, :x_baps do
              set :server, :x_baps_server do
                constants @baps_config, :x_baps_server_constant
              end
            end
          end
        end
      end
    end
  end
end
