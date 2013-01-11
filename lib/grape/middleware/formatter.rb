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
        negotiate_content_type
        read_body_input
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

      private

        def read_body_input
          request_method = request.request_method.to_s.upcase
          if [ 'POST', 'PUT' ].include?(request_method) && (! request.form_data?) && (! request.parseable_data?) && (request.content_length.to_i > 0)
            if env['rack.input'] && (body = env['rack.input'].read).strip.length > 0
              begin
                fmt = mime_types[request.media_type] if request.media_type
                if content_type_for(fmt)
                  parser = Grape::Parser::Base.parser_for fmt, options
                  unless parser.nil?
                    begin
                      body = parser.call body, env
                      env['rack.request.form_hash'] = env['rack.request.form_hash'] ? env['rack.request.form_hash'].merge(body) : body
                      env['rack.request.form_input'] = env['rack.input']
                    rescue Exception => e
                      throw :error, :status => 400, :message => e.message
                    end
                  end
                else
                  throw :error, :status => 406, :message => 'The requested content-type is not supported.'
                end
              ensure
                env['rack.input'].rewind
              end
            end
          end
        end

        def negotiate_content_type
          fmt = format_from_extension || format_from_params || options[:format] || format_from_header || options[:default_format]
          if content_type_for(fmt)
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

    end
  end
end
