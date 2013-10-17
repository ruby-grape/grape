$:.push File.expand_path("../lib", __FILE__)
require "grape/version"

Gem::Specification.new do |s|
  s.name        = "grape"
  s.version     = Grape::VERSION
  s.platform    = Gem::Platform::RUBY
  s.authors     = ["Michael Bleigh"]
  s.email       = ["michael@intridea.com"]
  s.homepage    = "https://github.com/intridea/grape"
  s.summary     = %q{A simple Ruby framework for building REST-like APIs.}
  s.description = %q{A Ruby framework for rapid API development with great conventions.}
  s.license     = "MIT"

  s.rubyforge_project = "grape"

  s.add_runtime_dependency 'rack', '>= 1.3.0'
  s.add_runtime_dependency 'rack-mount'
  s.add_runtime_dependency 'rack-accept'
  s.add_runtime_dependency 'activesupport'
  s.add_runtime_dependency 'multi_json', '>= 1.3.2'
  s.add_runtime_dependency 'multi_xml', '>= 0.5.2'
  s.add_runtime_dependency 'hashie', '>= 1.2.0'
  s.add_runtime_dependency 'virtus', '>= 1.0.0'
  s.add_runtime_dependency 'builder'

  s.add_development_dependency 'grape-entity', '>= 0.2.0'
  s.add_development_dependency 'rake'
  s.add_development_dependency 'maruku'
  s.add_development_dependency 'yard'
  s.add_development_dependency 'rack-test'
  s.add_development_dependency 'rspec', '~> 2.9'
  s.add_development_dependency 'bundler'

  s.files         = `git ls-files`.split("\n")
  s.test_files    = `git ls-files -- {test,spec,features}/*`.split("\n")
  s.executables   = `git ls-files -- bin/*`.split("\n").map{ |f| File.basename(f) }
  s.require_paths = ["lib"]
end
