class Grape::Middleware::Options < Grape::Middleware::Base
  def call(env)
    @env = env

    if env['REQUEST_METHOD'] == 'OPTIONS' and ! app.settings[:do_not_route_options]
      [204, { 'Allow' => allowed_methods_for_route.join(', ') }, []]
    else
      super
    end
  end
end