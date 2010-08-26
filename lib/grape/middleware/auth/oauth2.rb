module Grape::Middleware::Auth
  class OAuth2 < Grape::Middleware::Base
    def default_options
      {
        :token_class => 'AccessToken',
        :realm => 'OAuth API'
      }
    end
    
    def before
      if request['oauth_token']
        verify_token(request['oauth_token'])
      elsif env['Authorization'] && t = parse_authorization_header
        verify_token(t)
      end
    end
    
    def token_class
      @klass ||= eval(options[:token_class])
    end
    
    def verify_token(token)
      if token = token_class.verify(token)
        if token.expired?
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
        :message => 'The token provided has expired.',
        :status => status,
        :headers => {
          'WWW-Authenticate' => "OAuth realm='#{options[:realm]}', error='#{error}'"
        }
      }
    end
  end
end
    