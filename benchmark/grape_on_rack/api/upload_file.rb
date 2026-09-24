# frozen_string_literal: true

module Acme
  class UploadFile < Grape::API
    format :json

    desc 'Upload an image.'
    post 'avatar' do
      {
        filename: params[:image_file][:filename],
        size: params[:image_file][:tempfile].size
      }
    end

    desc 'Upload and download a file of any format.'
    post 'download' do
      filename = params[:file][:filename]
      content_type MIME::Types.type_for(filename)[0].to_s
      env['api.format'] = :binary
      header 'Content-Disposition', "attachment; filename*=UTF-8''#{CGI.escape(filename)}"
      params[:file][:tempfile].read
    end
  end
end
