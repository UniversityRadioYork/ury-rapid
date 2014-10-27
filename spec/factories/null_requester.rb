require 'ury_rapid/services/requests/null_requester'

FactoryGirl.define do
  factory(:null_requester,
          class: Rapid::Services::Requests::NullRequester) {}
end
