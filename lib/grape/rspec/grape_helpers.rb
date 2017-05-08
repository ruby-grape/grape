module RSpec #:nodoc:

  # Module to include in Rspec (Rails) request specs to have access
  # to default_parameters and default_headers helpers
  #
  # @example Add it through the spec_helper file
  #   RSpec.configure do |config|
  #     config.include RSpec::GrapeHelpers, :type => :request, :example_group => {:file_path => /spec\/api/}
  #   end
  #
  # @author Fabio Napoleoni <f.napoleoni@gmail.com>
  module GrapeHelpers
    extend ActiveSupport::Concern

    included do
      [:get, :post, :put, :delete, :head].each do |method|
        class_eval <<-EOV
        def #{method}(path, parameters = nil, headers = nil)
          # override empty params and headers with default
          parameters = combine_parameters(parameters, default_parameters)
          headers = combine_parameters(headers, default_headers)
          super(path, parameters, headers)
        end
        EOV
      end
    end

    # Default parameters for api calls
    #
    # @example Add a set of parameters to all api calls
    #   describe MyApi do
    #     include RSpec::GrapeHelpers
    #
    #     let(:default_parameters) { { p1: 'foo' } }
    #
    #     it "should merge parameters" do
    #       get :foo, :p2 => 'bar'
    #       request.params[:p1].should == 'foo'
    #       request.params[:p2].should == 'bar'
    #     end
    #
    #     it "should use default if other parameters are not given" do
    #       get :foo
    #       request.params[:p2].should == 'bar'
    #     end
    #   end
    #
    # @return [NilClass] by default nil, override if required
    def default_parameters
    end

    # Default headers for any api call
    #
    # @example Add a version through header
    #   describe MyApi do
    #     include RSpec::GrapeHelpers
    #
    #     let(:default_headers) { { 'Accept' => 'application/vnd.twitter-v1+json' } }
    #
    #     it "should use autentication if credentials are given" do
    #       get :foo
    #       request.headers['Accept'].should == 'application/vnd.twitter-v1+json'
    #     end
    #   end
    #
    # @return [NilClass] by default nil, override if required
    def default_headers
      http_basic_authentication_headers || nil
    end

    private

    # Combine hashes or nil arguments
    #
    # @param [Hash, nil] argument function argument
    # @param [Hash, nil] default class default
    #
    # @return [Hash, nil] a combined hash if both are hashes,
    #                     the not nil one if one of them is not nil
    #                     nil if both arguments are nil
    def combine_parameters argument, default
      # if both of them are hashes combine them
      if argument.is_a?(Hash) && default.is_a?(Hash)
        default.merge(argument)
      else
        # otherwise return not nil arg or eventually nil if both of them are nil
        argument || default
      end
    end

    # Returns http basic authentication header
    #
    # @example Authenticate with user and pass by default
    #   describe MyApi do
    #     include RSpec::GrapeHelpers
    #     let(:http_credentials) { %w(username password) }
    #
    #     it "should use autentication" do
    #       get :foo
    #       request.headers.should have_key 'REMOTE_USER'
    #       request.headers['REMOTE_USER'].should = 'username'
    #     end
    #   end
    #
    # @return [Hash, NilClass] the header if credentials are set, otherwise nil
    def http_basic_authentication_headers
      credentials = [http_username, http_password] if respond_to?(:http_username) && respond_to?(:http_password)
      credentials = http_credentials if respond_to?(:http_credentials)
      unless credentials.nil?
        {'HTTP_AUTHORIZATION' => ActionController::HttpAuthentication::Basic.encode_credentials(*credentials)}
      end
    end

    # Returns http basic authentication header
    # TODO to be implemented
    def http_digest_authentication_headers
      raise NotImplementedError
      #{'HTTP_AUTHORIZATION' => ActionController::HttpAuthentication::Digest.encode_credentials }
      #credentials = {
      #    :uri => request.env['REQUEST_URI'],
      #    :realm => "#{realm}",
      #    :username => "#{user}",
      #    :nonce => ActionController::HttpAuthentication::Digest.nonce,
      #    :opaque => ActionController::HttpAuthentication::Digest.opaque,
      #}
      #request.env['HTTP_AUTHORIZATION'] = ActionController::HttpAuthentication::Digest.encode_credentials(
      #    request.request_method, credentials, "#{password}", false
      #)
    end
  end
end