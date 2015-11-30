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
  s.add_runtime_dependency 'rack-mount'
  s.add_runtime_dependency 'rack-accept'
  s.add_runtime_dependency 'activesupport'
  s.add_runtime_dependency 'multi_json', '>= 1.3.2'
  s.add_runtime_dependency 'multi_xml', '>= 0.5.2'
  s.add_runtime_dependency 'hashie', '>= 2.1.0'
  s.add_runtime_dependency 'virtus', '>= 1.0.0'
  s.add_runtime_dependency 'builder'

  s.add_development_dependency 'grape-entity', '>= 0.4.4'
  s.add_development_dependency 'rake'
  s.add_development_dependency 'maruku'
  s.add_development_dependency 'yard'
  s.add_development_dependency 'rack-test'
  s.add_development_dependency 'rspec', '~> 3.0'
  s.add_development_dependency 'bundler'
  s.add_development_dependency 'cookiejar'
  s.add_development_dependency 'rack-contrib'
  s.add_development_dependency 'mime-types', '< 3.0'
  s.add_development_dependency 'appraisal'
  s.add_development_dependency 'benchmark-ips'
  s.add_development_dependency 'rubocop', '0.35.1'

  s.files         = Dir['**/*'].keep_if { |file| File.file?(file) }
  s.test_files    = Dir['spec/**/*']
  s.require_paths = ['lib']
end
