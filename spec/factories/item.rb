require 'bra/model/item'

FactoryGirl.define do
  factory :item, class: Bra::Model::Item do
    type     :library
    name     'Brown Girl In The Ring'
    origin   'playlist://0/0'
    duration 31415

    initialize_with { new(type, name, origin, duration) }
  end
end
