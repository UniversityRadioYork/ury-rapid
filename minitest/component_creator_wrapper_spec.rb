require 'minitest/autorun'
require 'ury_rapid/model/component_creator_wrapper'

describe Rapid::Model::ComponentCreatorWrapper do
  before do
    @hook      = Minitest::Mock.new
    @creator   = Minitest::Mock.new
    @component = Minitest::Mock.new
  end

  it 'forwards messages to the ComponentCreator verbatim' do
    subject = Rapid::Model::ComponentCreatorWrapper.new(@creator, ->(x) { x })

    @creator.expect :a_component_named_sue, @component, [:arg1, :arg2]
    subject.a_component_named_sue(:arg1, :arg2)
    @creator.verify
  end

  it 'sends resulting components through the hook' do
    @creator.expect :a_component_named_steve, @component
    @hook.expect :call, :hooked_component, [@component]

    subject = Rapid::Model::ComponentCreatorWrapper.new(@creator, @hook)
    subject.a_component_named_steve.must_equal(:hooked_component)

    @creator.verify
    @hook.verify
  end

  it 'complains if the hook is not a callable' do
    proc { Rapid::Model::ComponentCreatorWrapper.new(@creator, :a) }
      .must_raise(ArgumentError)
  end
end
