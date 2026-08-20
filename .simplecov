# frozen_string_literal: true

# Configuration only. `SimpleCov.start` lives in spec/spec_helper.rb.
if ENV['GITHUB_USER'] # only when running CI
  require 'simplecov-lcov'
  SimpleCov::Formatter::LcovFormatter.config do |c|
    c.report_with_single_file = true
    c.single_report_path = 'coverage/lcov.info'
  end

  SimpleCov.formatter = SimpleCov::Formatter::LcovFormatter
end

SimpleCov.enable_coverage :branch
SimpleCov.skip '/spec/'
