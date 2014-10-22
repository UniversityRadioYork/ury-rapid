require 'bundler/gem_tasks'
require 'rspec/core/rake_task'
require 'rake/testtask'

RSpec::Core::RakeTask.new

Rake::TestTask.new { |t| t.pattern = 'minitest/*.rb' }

task default: :spec
#task test: :spec
