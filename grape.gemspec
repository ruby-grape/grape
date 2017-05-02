$LOAD_PATH.push File.expand_path('../lib', __FILE__)
require 'grape/version'

Gem::Specification.new do |s|
  s.name        = 'grape'
  s.version     = Grape::VERSION
  s.platform    = Gem::Platform::RUBY
  s.authors     = ['Michael Bleigh']
  s.email       = ['michael@intridea.com']
  s.homepage    = 'https://github.com/ruby-grape/grape'
  s.summary     = 'A simple Ruby framework for building REST-like APIs.'
  s.description = 'A Ruby framework for rapid API development with great conventions.'
  s.license     = 'MIT'

  s.add_runtime_dependency 'rack', '>= 1.3.0'
  s.add_runtime_dependency 'mustermann-grape', '~> 1.0.0'
  s.add_runtime_dependency 'rack-accept'
  s.add_runtime_dependency 'activesupport'
  s.add_runtime_dependency 'virtus', '>= 1.0.0'
  s.add_runtime_dependency 'builder'

  s.files         = Dir['**/*'].keep_if { |file| File.file?(file) }
  s.test_files    = Dir['spec/**/*']
  s.require_paths = ['lib']
end
