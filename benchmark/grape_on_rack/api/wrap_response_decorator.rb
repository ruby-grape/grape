# frozen_string_literal: true

module Acme
  class WrapResponseDecorator
    def initialize(app)
      @app = app
    end

    def call(env)
      status, headers, body_proxy = @app.call(env)
      bodies = body_proxy.map do |body|
        { body: JSON.parse(body), status: status }.to_json
      end
      [200, headers, bodies]
    end
  end
end
