# when changing this file, run appraisal install ; rubocop -a gemfiles/*.gemfile

source 'https://rubygems.org'

gemspec

group :development, :test do
  gem 'bundler'
  gem 'rake'
  gem 'rubocop', '0.47.0'
end

group :development do
  gem 'guard'
  gem 'guard-rspec'
  gem 'guard-rubocop'
  gem 'yard'
  gem 'appraisal'
  gem 'benchmark-ips'
  gem 'redcarpet'
end

group :test do
  gem 'grape-entity', '~> 0.6'
  gem 'maruku'
  gem 'rack-test'
  gem 'rspec', '~> 3.0'
  gem 'cookiejar'
  gem 'rack-jsonp', require: 'rack/jsonp'
  gem 'mime-types'
  gem 'ruby-grape-danger', '~> 0.1.0', require: false
  gem 'coveralls', '~> 0.8.17', require: false
end
