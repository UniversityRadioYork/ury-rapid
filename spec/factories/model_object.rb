require 'bra/model'

# A minimal mock implementation of a ModelObject.
class MockModelObject
  include Bra::Model::ModelObject
end

FactoryGirl.define do
  factory :model_object, class: MockModelObject do
    handler_target nil
    
    ignore do
      channel Bra::Model::UpdateChannel.new
    end

    after :build do |item, evaluator|
      item.register_update_channel(evaluator.channel) if evaluator.channel
    end

    initialize_with { new(handler_target) }
  end
end
