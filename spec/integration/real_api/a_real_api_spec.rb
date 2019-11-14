describe 'Mounting a real API' do
  let!(:server_thread) do
    Thread.new do
      `fuser -k 9292/tcp  2>/dev/null`
      system("rackup spec/integration/real_api/example_api/config.ru 2>/dev/null")
    end
  end

  let(:method) { 'GET' }
  let(:request_start) { "curl -X #{method} localhost:9292" }

  before do
    # Start up server
    require 'timeout'
    begin
      Timeout.timeout(3) do
        loop do
          response = `#{request_start}/ping 2>/dev/null`
          break if response == 'pong'
        end
      end
      api_running = true
    rescue Timeout::Error
      api_running = false
    end
    expect(api_running).to be true
  end

  after do
    server_thread.terminate
    `fuser -k 9292/tcp 2>/dev/null`
  end

  it 'responds to an endpoint' do
    expect(`#{request_start}/endpoint 2>/dev/null`).to eq 'response'
  end

  it 'responds with the formatted headers' do
    headers = `#{request_start}/headers -H 'secret_PassWord: swordfish' 2>/dev/null`
    require 'json'
    expect(JSON.parse(headers)['Secret-Password']).to eq 'swordfish'
  end

  it 'responds with the formatted env' do
    response = `#{request_start}/env -H 'secret_PassWord: swordfish' 2>/dev/null`
    require 'json'
    expect(JSON.parse(response)['HTTP_SECRET_PASSWORD']).to eq 'swordfish'
  end
end
