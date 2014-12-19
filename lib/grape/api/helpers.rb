module Grape
  class API
    def self.const_missing(name)
      if name.to_sym == 'Helpers'.to_sym
        warn 'Grape::API::Helpers is deprecated use Grape::SharedParams and include_params instead'
        const_set(name, ::Grape::DSL::Helpers::BaseHelper)
      else
        super
      end
    end
  end
end
