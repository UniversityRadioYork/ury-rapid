require 'bra/model'

# A minimal mock implementation of a ModelObject.
class MockModelObject
  include Bra::Model::ModelObject
end

FactoryGirl.define do
  factory :model_object, class: MockModelObject do
    ignore do
      channel nil
    end

    after :build do |item, evaluator|
      item.register_update_channel(evaluator.channel) if evaluator.channel
    end
  end
end
