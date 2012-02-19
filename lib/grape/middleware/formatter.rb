require 'grape/middleware/base'

module Grape
  module Middleware
    class Formatter < Base
      include Formats

      def default_options
        { 
          :default_format => :txt,
          :formatters => {},
          :content_types => {},
          :parsers => {}
        }
      end
      
      def headers
        env.dup.inject({}){|h,(k,v)| h[k.downcase[5..-1]] = v if k.downcase.start_with?('http_'); h}
      end
      
      def before
        response_type = get_response_type
        if !env['rack.input'].nil? and (body = env['rack.input'].read).strip.length != 0
          parser = parser_for(response_type)
          unless parser.nil?
            begin
              body = parser.call(body)
              env['rack.request.form_hash'] = !env['rack.request.form_hash'].nil? ? env['rack.request.form_hash'].merge(body) : body
              env['rack.request.form_input'] = env['rack.input']
            rescue
              # It's possible that it's just regular POST content -- just back off
            end
          end
          env['rack.input'].rewind
        end
        env['api.format'] = response_type
      end

      def get_response_type
        format_from_extension || format_from_header || options[:default_format]
      end
      
      def format_from_extension
        parts = request.path.split('.')
        extension = parts.last.to_sym
        
        if parts.size > 1 && content_types.key?(extension)
          return extension
        end
        nil
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
        accept = headers['accept'] or return []

        accept.gsub(/\b/,'').scan(%r((\w+/[\w+.-]+)(?:(?:;[^,]*?)?;\s*q=([\d.]+))?)).sort_by { |_, q| -q.to_f }.map {|mime, _|
          mime.sub(%r(vnd\.[^+]+\+), '')
        }
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
    end
  end
end
