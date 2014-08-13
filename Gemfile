source 'http://rubygems.org'

gemspec

group :development, :test do
  gem 'rspec', '~> 3.0.0'
  gem 'rspec-mocks'
  
  gem 'rack-test', '~> 0.6.2', require: 'rack/test'
  gem 'cookiejar'
  gem 'rack-contrib'
  gem 'rubocop', '~> 0.24.1'
  gem 'guard'
  gem 'guard-rspec'
  gem 'guard-rubocop'
  gem 'mime-types'

  if RUBY_VERSION >= '2.0.0'
    gem 'pry-byebug'
  else
    gem 'pry-debugger'
  end
end

platforms :rbx do
  gem 'rubysl'
  gem 'rubinius-developer_tools'
  gem 'racc'
end
