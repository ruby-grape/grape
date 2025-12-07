# frozen_string_literal: true

# Inline checks from ruby-grape-danger (avoids plugins requiring GitHub API token)

has_app_changes = !git.modified_files.grep(/lib/).empty?
has_spec_changes = !git.modified_files.grep(/spec/).empty?

warn("There're library changes, but not tests. That's OK as long as you're refactoring existing code.", sticky: false) if has_app_changes && !has_spec_changes

message('We really appreciate pull requests that demonstrate issues, even without a fix. That said, the next step is to try and fix the failing tests!', sticky: false) if !has_app_changes && has_spec_changes

# Simplified changelog check (replaces danger-changelog plugin which requires github.* methods)
# Note: toc.check! from danger-toc plugin removed (not essential for CI)
has_changelog_changes = git.modified_files.include?('CHANGELOG.md') || git.added_files.include?('CHANGELOG.md')
warn('Please update CHANGELOG.md with a description of your changes.', sticky: false) if has_app_changes && !has_changelog_changes

(git.modified_files + git.added_files - %w[Dangerfile]).each do |file|
  next unless File.file?(file)

  contents = File.read(file)
  # rubocop:disable Style/SignalException -- `fail` is Danger's DSL method, not Kernel#fail
  if file.start_with?('spec')
    fail("`xit` or `fit` left in tests (#{file})") if /^\w*[xf]it/.match?(contents)
    fail("`fdescribe` left in tests (#{file})") if /^\w*fdescribe/.match?(contents)
  end
  # rubocop:enable Style/SignalException
end

# Output JSON report for GitHub Actions workflow_run to post as PR comment
if ENV['DANGER_REPORT_PATH']
  require 'json'

  report = {
    errors: violation_report[:errors].map(&:message),
    warnings: violation_report[:warnings].map(&:message),
    messages: violation_report[:messages].map(&:message)
  }

  File.write(ENV['DANGER_REPORT_PATH'], JSON.pretty_generate(report))
end
