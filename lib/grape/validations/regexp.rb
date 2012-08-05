module Grape
  module Validations
    
    class RegexpValidator < SingleOptionValidator
      def validate_param!(path, params)
        val = params.read(path)
        if val && !(val.to_s =~ @option )
          throw :error, :status => 400, :message => "invalid parameter: #{path}"
        end
      end
    end

  end
end
