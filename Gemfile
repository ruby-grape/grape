# when changing this file, run appraisal install ; rubocop -a gemfiles/*.gemfile

source 'https://rubygems.org'

gemspec

group :development, :test do
  gem 'bundler'
  gem 'rake'
  gem 'rubocop', '0.39.0'
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
  gem 'grape-entity', '0.5.0'
  gem 'maruku'
  gem 'rack-test'
  gem 'rspec', '~> 3.0'
  gem 'cookiejar'
  gem 'rack-jsonp', require: 'rack/jsonp'
  gem 'mime-types', '< 3.0'
  gem 'danger', '~> 2.0'
end
