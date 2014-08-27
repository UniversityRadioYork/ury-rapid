require 'simplecov'
require 'factory_girl'

RSpec.configure do |config|
  config.include FactoryGirl::Syntax::Methods

  config.expect_with :rspec do |c|
    c.syntax = :expect
  end
end

SimpleCov.start do
  add_group 'Server', 'lib/ury-rapid/server'
  add_group 'Common', 'lib/ury-rapid/common'
  add_group 'Models', 'lib/ury-rapid/model'
  add_group 'ServiceCommon', 'lib/ury-rapid/service_common'
  add_group 'BAPS', 'lib/ury-rapid/baps'
  add_filter 'spec'
end

FactoryGirl.find_definitions
