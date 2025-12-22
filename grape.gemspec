# frozen_string_literal: true

require_relative 'lib/grape/version'

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
  s.metadata    = {
    'bug_tracker_uri' => 'https://github.com/ruby-grape/grape/issues',
    'changelog_uri' => "https://github.com/ruby-grape/grape/blob/v#{s.version}/CHANGELOG.md",
    'documentation_uri' => "https://www.rubydoc.info/gems/grape/#{s.version}",
    'source_code_uri' => "https://github.com/ruby-grape/grape/tree/v#{s.version}",
    'rubygems_mfa_required' => 'true'
  }

  s.add_dependency 'activesupport', '>= 7.1'
  s.add_dependency 'dry-configurable'
  s.add_dependency 'dry-types', '>= 1.1'
  s.add_dependency 'mustermann-grape', '~> 1.1.0'
  s.add_dependency 'rack', '>= 2'
  s.add_dependency 'zeitwerk'

  s.files = Dir['lib/**/*', 'CHANGELOG.md', 'CONTRIBUTING.md', 'README.md', 'grape.png', 'UPGRADING.md', 'LICENSE', 'grape.gemspec']
  s.require_paths = ['lib']
  s.required_ruby_version = '>= 3.1'
end
