require 'rapid/model'

FactoryGirl.define do
  factory :playlist, class: Rapid::Model::ListModelObject do
    handler_target :playlist

    initialize_with { new(handler_target) }
  end
end
