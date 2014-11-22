require 'minitest'

require 'ury_rapid/model'
require 'ury_rapid/services/environment'
require 'ury_rapid/examples/hello_world_service'

class HelloWorldServiceTest < Minitest::Test

  # Called before every test method runs. Can be used
  # to set up fixture information.
  def setup
    @upchan  = Rapid::Model::DummyUpdateChannel.new
    @root    = Rapid::Model::HashModelObject.new(:foo)
    @view    = Rapid::Model::View.new(@root, @root)
    @env     = Rapid::Services::Environment.new(nil, @upchan, @view)
    @service = Rapid::Examples::HelloWorldService.new(@env)
  end

  # Called after every test method runs. Can be used to tear
  # down fixture information.
  def teardown
    # Do nothing
  end

  # Tests to see if the default message is 'Hello, world!'
  def test_message
    @service.run

    assert_equal 'Hello, world!', @env.find('/message').value
  end

  # Tests #message, to see if overriding the message works
  def test_message
    @service.message('test message')
    @service.run

    assert_equal 'test message', @env.find('/message').value
  end
end
