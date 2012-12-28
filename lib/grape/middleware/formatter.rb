require 'grape/middleware/base'

module Grape
  module Middleware
    class Formatter < Base

      def default_options
        {
          :default_format => :txt,
          :formatters => {},
          :parsers => {}
        }
      end

      def headers
        env.dup.inject({}){|h,(k,v)| h[k.to_s.downcase[5..-1]] = v if k.to_s.downcase.start_with?('http_'); h}
      end

      def before
        fmt = format_from_extension || format_from_params || options[:format] || format_from_header || options[:default_format]
        if content_type_for(fmt)
          if !env['rack.input'].nil? and (body = env['rack.input'].read).strip.length != 0
            parser = Grape::Parser::Base.parser_for fmt, options
            unless parser.nil?
              begin
                body = parser.call body, env
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

        if parts.size > 1
          extension = parts.last
          # avoid symbol memory leak on an unknown format
          return extension.to_sym if content_type_for(extension)
        end
        nil
      end

      def format_from_params
        fmt = Rack::Utils.parse_nested_query(env['QUERY_STRING'])["format"]
        # avoid symbol memory leak on an unknown format
        return fmt.to_sym if content_type_for(fmt)
        fmt
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
        formatter = Grape::Formatter::Base.formatter_for env['api.format'], options
        bodymap = bodies.collect do |body|
          formatter.call body, env
        end
        headers['Content-Type'] = content_type_for(env['api.format']) unless headers['Content-Type']
        Rack::Response.new(bodymap, status, headers).to_a
      end

    end
  end
end
