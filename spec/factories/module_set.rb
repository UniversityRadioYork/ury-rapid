require 'ury_rapid/modules/set'

# A dummy module, for test purposes.
class DummyModule
  def new(*_args)
  end

  def run
  end
end

# A dummy model builder, for test purposes.
class DummyModelBuilder
  def new(*_args)
  end

  def build(_name, _mod)
  end
end

FactoryGirl.define do
  factory :module_set, class: Rapid::Modules::Set do
    model_builder DummyModelBuilder.new

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
  end
end
