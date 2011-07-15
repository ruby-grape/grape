require 'grape/middleware/base'
require 'multi_json'

module Grape
  module Middleware
    class Formatter < Base
      include Formats

      def default_options
        { 
          :default_format => :txt,
          :formatters => {},
          :content_types => {}
        }
      end
      
      def headers
        env.dup.inject({}){|h,(k,v)| h[k.downcase] = v; h}
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
        mime_array.each do |t| 
          if mime_types.key?(t)
            return mime_types[t]
          end
        end
        nil
      end
      
      def mime_array
        accept = headers['accept']
        if accept
          accept.gsub(/\b/,'').
            scan(/(\w+\/[\w+]+)(?:;[^,]*q=([0-9.]+)[^,]*)?/i).
            sort_by{|a| -a[1].to_f}.
            map{|a| a[0]}
        else
          []
        end
      end
      
      def after
        status, headers, bodies = *@app_response
        formatter = formatter_for env['api.format']
        bodymap = bodies.collect do |body|
          formatter.call(body)
        end
        headers['Content-Type'] = content_types[env['api.format']]
        Rack::Response.new(bodymap, status, headers).to_a
      end

      def encode_json(object)
        if object.respond_to? :serializable_hash
          MultiJson.encode(object.serializable_hash)
        elsif object.respond_to? :to_json
          object.to_json
        else
          MultiJson.encode(object)
        end
      end
      
      def encode_txt(object)
        object.respond_to?(:to_txt) ? object.to_txt : object.to_s
      end
    end
  end
end
