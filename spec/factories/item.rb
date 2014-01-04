require 'bra/model'

FactoryGirl.define do
  factory :item, class: Bra::Model::Item do
    type     :library
    name     'Brown Girl In The Ring'
    origin   'playlist://0/0'
    duration 31415

    ignore do
      channel { Bra::Model::UpdateChannel.new }
    end

    after(:create) do |item, evaluator|
      item.register_update_channel(evaluator.channel) if evaluator.channel
    end

    initialize_with { new(type, name, origin, duration) }
  end
end
