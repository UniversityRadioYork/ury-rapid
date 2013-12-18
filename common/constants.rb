module Bra
  module Common
    module Constants
      # The API version
      # This follows Semantic Versioning (http://semver.org).
      # When changing this, update API_CHANGE_LOG.
      MAJOR_VERSION = 0
      MINOR_VERSION = 3
      PATCH_VERSION = 0
      VERSION = [MAJOR_VERSION, MINOR_VERSION, PATCH_VERSION].join('.')
    end
  end
end
