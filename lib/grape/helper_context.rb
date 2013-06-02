module Grape
  class HelperContext

    def set(params, request, env)
      reset!
      @params = params
      @request = request
      @env = env
    end

    def reset!
      instance_variables.each do |name|
        next if name.to_s == "@mock_proxy"
        instance_variable_set(name, nil)
      end
    end

    attr_reader :params, :request, :env
  end
end