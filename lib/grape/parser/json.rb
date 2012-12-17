module Grape
  module Parser
    module Json
      class << self

        def call(object, env)
          MultiJson.load(object)
        end

      end
    end
  end
end
