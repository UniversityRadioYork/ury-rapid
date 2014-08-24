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
        def playout_extensions
          log :log
          x_baps_extension
          info_extension
        end

        def x_baps_extension
          hash :x_baps, :x_baps do
            hash :server, :x_baps_server do
              option(:server_config).each do |(key, value)|
                component key, :constant, value, :x_baps_server_constant
              end
            end
          end
        end

        def info_extension
          hash :info, :info do
            component :channel_mode, :constant, true, :channel_mode
          end
        end
      end
    end
  end
end
