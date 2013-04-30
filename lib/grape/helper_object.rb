module Grape
  class HelperObject

    def set_context(params, request, env)
      reset_context
      @params = params
      @request = request
      @env = env
    end

    def reset_context
      instance_variables.each do |name|
        next if name.to_s == "@mock_proxy"
        instance_variable_set(name, nil)
      end
    end

    attr_reader :params, :request, :env
  end
end