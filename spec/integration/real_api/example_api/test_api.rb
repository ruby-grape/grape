class TestAPI < Grape::API
  get 'ping' do
    'pong'
  end

  get 'endpoint' do
    'response'
  end

  get 'headers' do
    headers.to_json
  end

  get 'env' do
    env.to_json
  end
end
