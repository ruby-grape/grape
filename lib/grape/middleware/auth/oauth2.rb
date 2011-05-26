module Grape::Middleware::Auth
  class OAuth2 < Grape::Middleware::Base
    def default_options
      {
        :token_class => 'AccessToken',
        :realm => 'OAuth API',
        :parameter => %w(bearer_token oauth_token),
        :header => [/Bearer (.*)/i, /OAuth (.*)/i]
      }
    end
    
    def before
      verify_token(token_parameter || token_header)
    end

    def token_parameter
      Array(options[:parameter]).each do |p|
        return request[p] if request[p]
      end
      nil
    end

    def token_header
      return false unless env['Authorization']
      Array(options[:header]).each do |regexp|
        if env['Authorization'] =~ regexp
          return $1
        end
      end
      nil
    end
    
    def token_class
      @klass ||= eval(options[:token_class])
    end
    
    def verify_token(token)
      if token = token_class.verify(token)
        if token.respond_to?(:expired?) && token.expired?
          error_out(401, 'expired_token')
        else
          if token.permission_for?(env)
            env['api.token'] = token
          else
            error_out(403, 'insufficient_scope')
          end
        end
      else
        error_out(401, 'invalid_token')
      end
    end
    
    def parse_authorization_header
      if env['Authorization'] =~ /oauth (.*)/i
        $1
      end
    end
    
    def error_out(status, error)
      throw :error, {
        :message => error,
        :status => status,
        :headers => {
          'WWW-Authenticate' => "OAuth realm='#{options[:realm]}', error='#{error}'"
        }
      }
    end
  end
end
    
