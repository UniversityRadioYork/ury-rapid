require_relative '../models/set'
require_relative '../models/variable'

module Bra
  module Baps
    # Model objects specific to BAPS.
    #
    # The BAPS module exposes its own custom model tree in the x-baps/ section
    # of BRA's URL hierarchy, containing information specific to the BAPS
    # playout system.
    module Models
      # Object that creates the BAPS model set, given a model root and config.
      class Creator
        def initialize(root, config)
          @root = root
          @config = config
        end

        def run
          xbaps = Bra::Models::Set.new(:x_baps).move_to(@root, :x_baps)
          server.move_to(xbaps, :server)
        end

        # Constructs and populates a BAPS model set under the given model root
        #
        # The BAPS models are initially populated with values from the config
        # given.
        #
        # model  - The root of the model to which the BAPS model tree should be
        #          added.
        # config - The config dict from which the BAPS model will be populated.
        #
        # @return [Model] The initial model root, which may have been mutated.
        def self.create(root, config)
          new(root, config).run
          root
        end

        private

        def server
          Bra::Models::Set.new(:x_baps_server).tap(
            &method(:add_server_constants)
          )
        end

        def add_server_constants(server)
          @config.each { |key, value| add_server_constant(server, key, value) }
        end

        def add_server_constant(server, key, value)
          Bra::Models::Constant.new(
            value, :x_baps_server_constant
          ).move_to(server, key)
        end
      end
    end
  end
end
