class Grape::Middleware::BadMethod < Grape::Middleware::Base
  def call(env)
    @env = env
    allowed_methods = allowed_methods_for_route

    unless allowed_methods.include? env['REQUEST_METHOD']
      [405, { 'Allow' => allowed_methods.join(', ') }, []]
    else
      super
    end
  end
end