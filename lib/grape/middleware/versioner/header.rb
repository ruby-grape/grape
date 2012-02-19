require 'grape/middleware/base'

module Grape
  module Middleware
    module Versioner
      # This middleware sets various version related rack environment variables
      # based on the HTTP Accept header with the pattern:
      # application/vnd.:vendor-:version+:format
      #
      # Example: For request header
      #    Accept: application/vnd.mycompany-v1+json
      #
      # The following rack env variables are set:
      #
      #    env['api.type']    => 'application'
      #    env['api.subtype'] => 'vnd.mycompany-v1+json'
      #    env['api.vendor]   => 'mycompany'
      #    env['api.version]  => 'v1'
      #    env['api.format]   => 'format'
      #
      # If version does not match this route, then a 404 is throw with
      # X-Cascade header to alert Rack::Mount to attempt the next matched
      # route.
      class Header < Base
        def before
          accept = env['HTTP_ACCEPT'] || ""

          if options[:version_options] && options[:version_options].keys.include?(:strict) && options[:version_options][:strict]
            if (incorrect_header?(accept))  && options[:version_options][:using] == :header
              throw :error, :status => 404, :headers => {'X-Cascade' => 'pass'}, :message => "404 API Version Not Found"
            end
          end
          accept.strip.scan(/^(.+?)\/(.+?)$/) do |type, subtype|
            env['api.type']    = type
            env['api.subtype'] = subtype

            subtype.scan(/vnd\.(.+)?-(.+)?\+(.*)?/) do |vendor, version, format|
              is_vendored = options[:version_options] && options[:version_options][:vendor]
              is_vendored_match = is_vendored ? options[:version_options][:vendor] == vendor : true

              if (options[:versions] && !options[:versions].include?(version)) || !is_vendored_match
                throw :error, :status => 404, :headers => {'X-Cascade' => 'pass'}, :message => "404 API Version Not Found"
              end

              env['api.version'] = version
              env['api.vendor']  = vendor
              env['api.format']  = format  # weird that Grape::Middleware::Formatter also does this
            end
          end
        end

        protected
        def incorrect_header?(header)
          (header.strip =~ /application\/vnd\.(.+?)-(.+?)\+(.+?)/).nil?
        end
      end
    end
  end
end
