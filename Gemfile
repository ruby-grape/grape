# frozen_string_literal: true

source('https://rubygems.org')

gemspec

group :development, :test do
  gem 'builder', require: false
  gem 'bundler'
  gem 'rake'
  gem 'rubocop', '1.88.0', require: false
  gem 'rubocop-performance', '1.26.1', require: false
  gem 'rubocop-rspec', '3.10.2', require: false
end

group :development do
  gem 'benchmark-ips'
  gem 'benchmark-memory'
  gem 'irb'
end

group :test do
  gem 'danger', require: false
  gem 'danger-changelog', require: false
  gem 'danger-pr-comment', require: false
  gem 'rack-contrib', require: false
  gem 'rack-test', '~> 2.1'
  gem 'rspec', '~> 3.13'
  gem 'simplecov', '~> 0.21', require: false
  gem 'simplecov-lcov', '~> 0.8', require: false
end

platforms :jruby do
  gem 'racc'
end
