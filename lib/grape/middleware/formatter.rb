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
        env.dup.inject({}){|h,(k,v)| h[k.downcase] = v; h}
      end
      
      def before
        fmt = format_from_extension || format_from_header || options[:default_format]
        if content_types.key?(fmt)
          if !env['rack.input'].nil? and (body = env['rack.input'].read).strip.length != 0
            parser = parser_for fmt
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

        unless env['api.tilt.template']
          formatter = formatter_for(env['api.format'])
        else
          formatter = Proc.new do |obj|
            return [500, {}, ["Use Rack::Config to set 'api.tilt.root' in config.ru"]] \
              unless env['api.tilt.root']
            tilt = ::Tilt.new(File.join(env['api.tilt.root'], env['api.tilt.template']))
            tilt.render(Object.new, { :object => obj }) # scope is new object.
          end
        end

        bodymap = bodies.collect do |body|
          formatter.call(body)
        end
        headers['Content-Type'] = content_types[env['api.format']]
        Rack::Response.new(bodymap, status, headers).to_a
      end
    end
  end
end
