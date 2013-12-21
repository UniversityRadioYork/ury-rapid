require 'simplecov'
SimpleCov.start do
  add_group 'Server', 'lib/bra/server'
  add_group 'Common', 'lib/bra/common'
  add_group 'Models', 'lib/bra/models'
  add_group 'DriverCommon', 'lib/bra/driver_common'
  add_group 'BAPS', 'lib/bra/baps'
  add_filter 'spec'
end
