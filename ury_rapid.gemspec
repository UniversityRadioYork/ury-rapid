# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'ury_rapid/common/constants'
require 'English'

Gem::Specification.new do |spec|
  spec.name          = 'ury_rapid'
  spec.version       = Rapid::Common::Constants::VERSION
  spec.authors       = ['Matt Windsor']
  spec.email         = ['computing@ury.org.uk']
  spec.description   = <<-EOF
    Rapid is an API server and abstraction layer for radio station playout
    systems.  It provides a HTTP and WebSocket based interface for both
    querying and modifying a playout system's state.

    Rapid was originally developed for University Radio York's BAPS system, but
    is intended to be extensible to cover other systems.
  EOF
  spec.summary       = 'Lifts and separates playout systems from their clients'
  spec.homepage      = 'http://github.com/UniversityRadioYork/Rapid'
  spec.license       = 'BSD-2-Clause'

  spec.files         = `git ls-files`.split($INPUT_RECORD_SEPARATOR)
  spec.executables   = spec.files.grep(/^bin\//) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(/^(test|spec|features)\//)
  spec.require_paths = ['lib']

  spec.add_development_dependency 'bundler', '~> 1.7'
  spec.add_development_dependency 'factory_girl', '~> 4'
  spec.add_development_dependency 'rake'
  spec.add_development_dependency 'rspec', '~> 3'
  spec.add_development_dependency 'scss-lint'
  spec.add_development_dependency 'simplecov'
  spec.add_development_dependency 'minitest', '~> 5.4'

  spec.add_runtime_dependency 'activesupport'
  spec.add_runtime_dependency 'colored'
  spec.add_runtime_dependency 'compass'
  spec.add_runtime_dependency 'compo', '~> 0.5'
  spec.add_runtime_dependency 'eventmachine', '~> 1.0'
  spec.add_runtime_dependency 'haml'
  spec.add_runtime_dependency 'kankri', '~> 0.1'
  spec.add_runtime_dependency 'sass'
  spec.add_runtime_dependency 'sinatra'
  spec.add_runtime_dependency 'sinatra-contrib'
  spec.add_runtime_dependency 'sinatra-websocket'
  spec.add_runtime_dependency 'thin'
end
