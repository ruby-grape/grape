def encode_basic_auth(username, password)
  "Basic " + Base64.encode64("#{username}:#{password}")
end
