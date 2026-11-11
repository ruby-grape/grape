# frozen_string_literal: true

require('rubygems')
require('bundler')
Bundler.setup(:default, :test, :development)

Bundler::GemHelper.install_tasks

# Releases run through the Release workflow, not Bundler's tasks; see RELEASING.md.
%w[release release:guard_clean release:source_control_push release:rubygem_push].each { |name| Rake::Task[name].clear }
desc('Release through the Release GitHub Actions workflow, see RELEASING.md')
task(:release) { abort('Release through the Release GitHub Actions workflow; see RELEASING.md.') }

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

# Duel's tasks, in its own bundle (gemfiles/duel.gemfile).
begin
  require('duel/rake_task')
  Duel::RakeTask.new
rescue LoadError
  # (Any other bundle, which hasn't got Duel.)
end

# The release workflow's tasks, in its own bundle (gemfiles/release.gemfile).
begin
  require_relative('tasks/release')
  GrapeRelease.workflow.install_tasks
rescue LoadError => e
  # (Any other bundle, which hasn't got ruby-gem-release.)
  raise unless e.path.to_s.start_with?('ruby-gem-release')
end
