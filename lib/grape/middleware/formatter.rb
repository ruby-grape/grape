require 'grape/middleware/base'
require 'multi_json'

module Grape
  module Middleware
    class Formatter < Base
      CONTENT_TYPES = {
        :xml => 'application/xml',
        :json => 'application/json',
        :atom => 'application/atom+xml',
        :rss => 'application/rss+xml'
      }
      
      def default_options
        { 
          :default_format => :json,
          :content_types => {}
        }
      end
      
      def content_types
        CONTENT_TYPES.merge(options[:content_types])
      end
      
      def before
        fmt = format_from_extension || format_from_header || options[:default_format]
        
        if content_types.key?(fmt)
          env['api.format'] = fmt          
        else
          throw :error, :status => 406, :message => 'The requested format is not supported.'
        end
      end
      
      def format_from_extension
        parts = request.path.split('.')
        hit = parts.last.to_sym
        
        if parts.size <= 1
          nil
        else
          hit
        end
      end
      
      def format_from_header
        # TODO: Implement Accept header parsing.
      end
      
      def after
        status, headers, bodies = *@app_response
        bodies.map! do |body|
          MultiJson.encode(body)
        end
        [status, headers, bodies]
      end
    end
  end
end