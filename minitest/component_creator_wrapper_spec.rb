require 'minitest/autorun'
require 'ury_rapid/model/components/creator_wrapper'

describe Rapid::Model::Components::CreatorWrapper do
  before do
    @hook      = Minitest::Mock.new
    @creator   = Minitest::Mock.new
    @component = Minitest::Mock.new
  end

  it 'forwards messages to the ComponentCreator verbatim' do
    subject = Rapid::Model::Components::CreatorWrapper.new(@creator, ->(_, x) { x })

    @creator.expect :a_component_named_sue, @component, [:arg1, :arg2]
    subject.a_component_named_sue(:arg1, :arg2)
    @creator.verify
  end

  it 'sends resulting components through the hook' do
    @creator.expect :a_component_named_steve, @component
    @hook.expect :call, :hooked_component, [:a_component_named_steve, @component]

    subject = Rapid::Model::Components::CreatorWrapper.new(@creator, @hook)
    subject.a_component_named_steve.must_equal(:hooked_component)

    @creator.verify
    @hook.verify
  end

  it 'complains if the hook is not a callable' do
    proc { Rapid::Model::Components::CreatorWrapper.new(@creator, :a) }
      .must_raise(ArgumentError)
  end
end
