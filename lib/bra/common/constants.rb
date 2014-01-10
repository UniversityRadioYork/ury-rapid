module Bra
  module Common
    # Constants used throughout BRA
    module Constants
      # The API version
      # This follows Semantic Versioning (http://semver.org).
      # When changing this, update API_CHANGE_LOG.
      MAJOR_VERSION = 0
      MINOR_VERSION = 4
      PATCH_VERSION = 1
      VERSION = [MAJOR_VERSION, MINOR_VERSION, PATCH_VERSION].join('.')

      # The default configuration file (can be overridden at run-time)
      CONFIG_FILE = 'config.yml'
    end
  end
end
