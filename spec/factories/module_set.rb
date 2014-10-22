require 'ury_rapid/modules/set'

# A dummy module, for test purposes.
class DummyModule
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
  factory :module_set, class: Rapid::Modules::Set do
    environment DummyEnvironment.new

    factory(:empty_module_set) {}

    factory :non_empty_module_set do
      ignore do
        modules %i(module1 module3 module5 module7)
        enabled []
        module_class DummyModule
      end

      after :build do |set, ev|
        ev.modules.each { |m| set.configure(m, ev.module_class) {} }
        ev.enabled.each { |m| set.enable(m) }
      end
    end

    initialize_with { new(environment) }
  end
end
