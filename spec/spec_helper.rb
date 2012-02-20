$LOAD_PATH.unshift(File.dirname(__FILE__))
$LOAD_PATH.unshift(File.join(File.dirname(__FILE__), '..', 'lib'))
$LOAD_PATH.unshift(File.join(File.dirname(__FILE__), 'support'))

$stdout = StringIO.new

require 'grape'

require 'rubygems'
require 'bundler'
Bundler.setup :default, :test

require 'rack/test'

require 'base64'
def encode_basic(username, password)
  "Basic " + Base64.encode64("#{username}:#{password}")
end

RSpec.configure do |config|
  config.include Rack::Test::Methods
end

# Versioning

# Returns the path with options[:version] prefixed if options[:using] is :path.
# Returns normal path otherwise.
def versioned_path(options = {})
  case options[:using]
  when :path
    File.join('/', options[:prefix] || '', options[:version], options[:path])
  when :header
    File.join('/', options[:prefix] || '', options[:path])
  else
    raise ArgumentError.new("unknown versioning strategy: #{options[:using]}")
  end
end

def versioned_headers(options)
  case options[:using]
  when :path
    {}  # no-op
  when :header
    {
      'HTTP_ACCEPT' => "application/vnd.#{options[:vendor]}-#{options[:version]}+#{options[:format]}"
    }
  else
    raise ArgumentError.new("unknown versioning strategy: #{options[:using]}")
  end
end

def versioned_get(path, version_name, version_options = {})
  path    = versioned_path(version_options.merge(:version => version_name, :path => path))
  headers = versioned_headers(version_options.merge(:version => version_name))
  get path, {}, headers
end

# Helpers for decoding string
def decode(accept, string)
  if accept.to_sym == :gzip
    gunzip string
  elsif accept.to_sym == :deflate
    inflate string
  end
end

def inflate(string)
  zstream = Zlib::Inflate.new(-Zlib::MAX_WBITS)
  buf = zstream.inflate(string)
  zstream.finish
  zstream.close
  buf
end

def gunzip(string)
  zstream = Zlib::GzipReader.new(StringIO.new(string))
  result = zstream.read
  zstream.close
  result
end
