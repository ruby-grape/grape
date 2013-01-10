module Grape
  module Validations

    class RegexpValidator < SingleOptionValidator
      def validate_param!(attr_name, params)
        if params[attr_name] && !( params[attr_name].to_s =~ @option )
          raise Grape::Exceptions::ValidationError, :status => 400, :param => attr_name, :message => i18n_message(:regexp, attr_name)
        end
      end
    end

  end
end
