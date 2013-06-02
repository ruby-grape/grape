class Grape::Middleware::Method < Grape::Middleware::Base
  def call(env)
    @env = env
    allowed_methods = allowed_methods_for_route

    unless allowed_methods.include? env['REQUEST_METHOD']
      [405, { 'Allow' => allowed_methods.join(', '), 'Content-Type' => 'text/plain' }, []]
    else
      super
    end
  end
end