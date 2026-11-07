# frozen_string_literal: true

source('https://rubygems.org')

gemspec

group :development, :test do
  gem 'builder', require: false
  gem 'bundler'
  gem 'rake'
  gem 'rubocop', '1.92.2', require: false
  gem 'rubocop-exception_messages', '0.2.0', require: false
  gem 'rubocop-performance', '1.27.0', require: false
  gem 'rubocop-rspec', '3.10.2', require: false
end

group :development do
  gem 'benchmark-ips'
  gem 'benchmark-memory'
  gem 'irb'
end

group :test do
  gem 'rack-contrib', require: false
  gem 'rack-test', '~> 2.1'
  # ActiveSupport::XmlMini, Grape's XML backend without multi_xml, parses with
  # REXML, a bundled gem rather than a default one.
  gem 'rexml', require: false
  gem 'rspec', '~> 3.13'
  gem 'simplecov', '~> 1.1', require: false
end

platforms :jruby do
  gem 'racc'
end
