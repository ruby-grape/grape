# frozen_string_literal: true

require('rubygems')
require('bundler')
Bundler.setup(:default, :test, :development)

Bundler::GemHelper.install_tasks

require('rspec/core/rake_task')
RSpec::Core::RakeTask.new(:spec) do |spec|
  spec.pattern = 'spec/**/*_spec.rb'
  spec.exclude_pattern = 'spec/integration/**/*_spec.rb'
end

RSpec::Core::RakeTask.new(:rcov) do |spec|
  spec.pattern = 'spec/**/*_spec.rb'
  spec.rcov = true
end

task(:spec)

require('rainbow/ext/string') unless String.respond_to?(:color)

require('rubocop/rake_task')
RuboCop::RakeTask.new

task(default: %i[rubocop spec])

# Duel requires Ruby 3.4 or later
if Gem::Version.new(RUBY_VERSION) >= Gem::Version.new('3.4')
  require('duel/rake_task')
  Duel::RakeTask.new
end
