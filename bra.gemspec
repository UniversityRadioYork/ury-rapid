# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'bra/common/constants'

Gem::Specification.new do |spec|
  spec.name          = 'bra'
  spec.version       = Bra::Common::Constants::VERSION
  spec.authors       = ['Matt Windsor']
  spec.email         = ['matt.windsor@ury.org.uk']
  spec.description   = ''
  spec.summary       = 'Lifts and separates playout systems from their clients'
  spec.homepage      = 'http://github.com/UniversityRadioYork/bra'
  spec.license       = 'BSD'

  spec.files         = `git ls-files`.split($/)
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ['lib']

  spec.add_development_dependency 'bundler', '~> 1.3'
  spec.add_development_dependency 'rake'
  spec.add_development_dependency 'rspec'
end
