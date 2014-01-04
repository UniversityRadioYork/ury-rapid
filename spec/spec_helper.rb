require 'simplecov'
require 'factory_girl'

RSpec.configure do |config|
  config.include FactoryGirl::Syntax::Methods

  config.expect_with :rspec do |c|
    c.syntax = :expect
  end
end

SimpleCov.start do
  add_group 'Server', 'lib/bra/server'
  add_group 'Common', 'lib/bra/common'
  add_group 'Models', 'lib/bra/model'
  add_group 'DriverCommon', 'lib/bra/driver_common'
  add_group 'BAPS', 'lib/bra/baps'
  add_filter 'spec'
end

FactoryGirl.find_definitions
