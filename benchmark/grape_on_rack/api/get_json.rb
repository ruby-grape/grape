# frozen_string_literal: true

module Acme
  class GetJson < Grape::API
    format :json
    desc 'Flips reticulated in a collection of splines passed as JSON in a query string.'
    resource :reticulated_splines do
      before do
        params.each_pair do |k, v|
          params[k] = begin
            JSON.parse(v)
          rescue StandardError
            v
          end
        end
      end
      params do
        requires :splines, type: Array do
          requires :id, type: Integer
          requires :reticulated, type: Boolean
        end
      end
      get do
        params[:splines].map do |spline|
          spline.merge(reticulated: !spline[:reticulated])
        end
      end
    end
  end
end
