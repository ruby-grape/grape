$LOAD_PATH.unshift(File.join(File.dirname(__FILE__), '..', 'lib'))
require 'grape'
require 'benchmark/memory'

class VotingApi < Grape::API
  logger Logger.new(STDOUT)

  helpers do
    def logger
      VotingApi.logger
    end
  end

  namespace 'votes' do
    get do
      logger
    end
  end
end

class PostApi < Grape::API
  mount VotingApi
end

class CommentAPI < Grape::API
  mount VotingApi
end

env = Rack::MockRequest.env_for('/votes', method: 'GET')

Benchmark.memory do |api|
  calls = 1000

  api.report('using Array') do
    VotingApi.instance_variable_set(:@setup, [])
    calls.times { PostApi.call(env) }
    puts " setup size: #{VotingApi.instance_variable_get(:@setup).size}"
  end

  api.report('using Set') do
    VotingApi.instance_variable_set(:@setup, Set.new)
    calls.times { PostApi.call(env) }
    puts " setup size: #{VotingApi.instance_variable_get(:@setup).size}"
  end

  api.compare!
end
