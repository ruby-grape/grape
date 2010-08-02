$LOAD_PATH.unshift(File.dirname(__FILE__))
$LOAD_PATH.unshift(File.join(File.dirname(__FILE__), '..', 'lib'))

require 'grape'

require 'rubygems'
require 'bundler'
Bundler.setup :test

require 'rspec'
require 'rack/test'

RSpec.configure do |config|
  
end
