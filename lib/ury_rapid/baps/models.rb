require 'ury_rapid/model/structures/playout_model'

module Rapid
  module Baps
    # Model objects specific to BAPS
    #
    # The BAPS module exposes its own custom model tree in the x-baps/ section
    # of Rapid's URL hierarchy, containing information specific to the BAPS
    # playout system.
    module Model
      # Object that creates the BAPS model set, given a model root and config.
      class Creator < Rapid::Model::Structures::PlayoutModel
        def playout_extensions
        end

        def x_baps_extension
        end

        def info_extension
        end
      end
    end
  end
end
