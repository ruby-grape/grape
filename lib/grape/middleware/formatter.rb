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
        begin
          bodymap = bodies.collect do |body|
            formatter.call body, env
          end
        rescue Grape::Exceptions::InvalidFormatter => e
          throw :error, :status => 500, :message => e.message
        end
        headers['Content-Type'] = content_type_for(env['api.format']) unless headers['Content-Type']
        Rack::Response.new(bodymap, status, headers).to_a
      end

      private

        # store read input in env['api.request.input']
        def read_body_input
          if (request.post? || request.put? || request.patch?) && (! request.form_data?) && (! request.parseable_data?) && (request.content_length.to_i > 0)
            if env['rack.input'] && (body = (env['api.request.input'] = env['rack.input'].read)).length > 0
              read_rack_input body
            end
          end
        end

        # store parsed input in env['api.request.body']
        def read_rack_input(body)
          begin
            fmt = mime_types[request.media_type] if request.media_type
            if content_type_for(fmt)
              parser = Grape::Parser::Base.parser_for fmt, options
              if parser
                begin
                  body = (env['api.request.body'] = parser.call(body, env))
                  if body.is_a?(Hash)
                    env['rack.request.form_hash'] = env['rack.request.form_hash'] ? 
                      env['rack.request.form_hash'].merge(body) : 
                      body
                  end
                  env['rack.request.form_input'] = env['rack.input']
                rescue Exception => e
                  throw :error, :status => 400, :message => e.message
                end
              end
            else
              throw :error, :status => 406, :message => "The requested content-type '#{request.media_type}' is not supported."
            end
          ensure
            env['rack.input'].rewind
          end
        end

        def negotiate_content_type
          fmt = format_from_extension || format_from_params || options[:format] || format_from_header || options[:default_format]
          if content_type_for(fmt)
            env['api.format'] = fmt
          else
            throw :error, :status => 406, :message => "The requested format '#{fmt}' is not supported."
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
          accept_into_mime_and_quality = %r(
            (
              \w+/[\w+.-]+)     # eg application/vnd.example.myformat+xml
            (?:
             (?:;[^,]*?)?       # optionally multiple formats in a row
             ;\s*q=([\d.]+)     # optional "quality" preference (eg q=0.5)
            )?
          )x  # x = extended regular expression with comments etc
          vendor_prefix_pattern = %r(vnd\.[^+]+\+)

          accept.scan(accept_into_mime_and_quality).
            sort_by { |_, quality_preference| -quality_preference.to_f }.
            map {|mime, _| mime.sub(vendor_prefix_pattern, '') }
        end

    end
  end
end
