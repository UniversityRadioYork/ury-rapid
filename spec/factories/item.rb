require 'ury_rapid/model'

FactoryGirl.define do
  factory :item, class: Rapid::Model::Item do
    type :library
    name 'Brown Girl In The Ring'
    origin 'playlist://0/0'
    duration 31_415

    ignore do
      channel Rapid::Model::UpdateChannel.new
    end

    after :build do |item, evaluator|
      item.register_update_channel(evaluator.channel) if evaluator.channel
    end

    initialize_with { new(type, name, origin, duration) }
  end
end
