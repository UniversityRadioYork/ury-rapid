require 'bra/model'

FactoryGirl.define do
  factory :playlist, class: Bra::Model::ListModelObject do
    handler_target :playlist

    initialize_with { new(handler_target) }
  end
end
