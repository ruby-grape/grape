unless Rack::Test::Session.method_defined?(:patch)
  module Rack
    module Test
      module Methods
        module Patch
          extend Forwardable
          def_delegators :current_session, *[:patch]
        end
      end
    end
  end

  module Rack
    module Test
      class Session
        def patch(uri, params = {}, env = {}, &block)
          env = env_for(uri, env.merge(:method => "PATCH", :params => params))
          process_request(uri, env, &block)
        end
      end
    end
  end
else
  raise LoadError, "Remove spec/support/rack_patch.rb | rack-test #{Rack::Test::VERSION} has a method patch"
end