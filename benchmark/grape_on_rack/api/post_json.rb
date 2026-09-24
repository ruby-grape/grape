# frozen_string_literal: true

module Acme
  class PostJson < Grape::API
    format :json
    desc 'Creates a spline that can be reticulated.'
    params do
      requires :reticulated, type: String, documentation: { param_type: 'body' }
    end
    resource :spline do
      post do
        { reticulated: params[:reticulated] }
      end
    end
  end
end
