require 'ury_rapid/services/set'

# A dummy service, for test purposes.
class DummyService
  def initialize(_environment)
  end

  def run
  end
end

# A dummy environment, for test purposes.
class DummyEnvironment
  def insert_components(_url, &_block)
  end

  def find(_)
    nil
  end

  def with_local_root(_)
    self
  end
end

FactoryGirl.define do
  factory :service_set, class: Rapid::Services::Set do
    environment DummyEnvironment.new

    factory(:empty_service_set) {}

    factory :non_empty_service_set do
      ignore do
        services %i(service1 service3 service5 service7)
        enabled []
        service_class DummyService
      end

      after :build do |set, ev|
        ev.services.each { |m| set.configure(m, ev.service_class) {} }
        ev.enabled.each { |m| set.enable(m) }
      end
    end

    initialize_with { new(environment) }
  end
end
