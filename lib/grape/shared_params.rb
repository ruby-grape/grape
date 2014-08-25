module Grape
  module SharedParams
    include Grape::DSL::Helpers::BaseHelper

    module_function
    def shared_params
      @shared_params ||= {}
    end
  end
end
