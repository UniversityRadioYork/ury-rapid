require 'ury-rapid/service_common/requests/null_requester'

FactoryGirl.define do
  factory(:null_requester,
          class: Rapid::ServiceCommon::Requests::NullRequester) {}
end
