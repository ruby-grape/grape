require 'grape/middleware/base'

module Grape
  module Middleware
    class Error < Base
    
      def default_options
      { 
        :default_status => 403, # default status returned on error
        :rescue => true, # true to rescue all exceptions
        :default_message => "",
        :format => :txt,
        :formatters => {},
        :backtrace => false, # true to display backtrace
      }
      end

      FORMATTERS = {
        :json => :format_json,
        :txt => :format_txt,
      }

      def formatters
        FORMATTERS.merge(options[:formatters])
      end

      def formatter_for(api_format)
        spec = formatters[api_format]
        case spec
        when nil
          lambda { |obj| obj }
        when Symbol
          method(spec)
        else
          spec
        end
      end

      def format_json(message, backtrace)
        result = message.is_a?(Hash) ? message : { :error => message }
        if (options[:backtrace] && backtrace && ! backtrace.empty?)
          result = result.merge({ :backtrace => backtrace })
        end
        result.to_json
      end
      
      def format_txt(message, backtrace)
        result = message.is_a?(Hash) ? message.to_json : message
        if options[:backtrace] && backtrace && ! backtrace.empty?
          result += "\r\n "
          result += backtrace.join("\r\n ")
        end
        result
      end

      def call!(env)
        @env = env
        
        begin
          error_response(catch(:error){ 
            return @app.call(@env) 
          })
        rescue Exception => e
          raise unless options[:rescue]
          error_response({ :message => e.message, :backtrace => e.backtrace })
        end
        
      end
      
      def error_response(error = {})
        status = error[:status] || options[:default_status]
        message = error[:message] || options[:default_message]
        headers = error[:headers] || {}
        backtrace = error[:backtrace] || []
        Rack::Response.new([format_message(message, backtrace, status)], status, headers).finish
      end
      
      def format_message(message, backtrace, status)
        formatter = formatter_for(options[:format])
        throw :error, :status => 406, :message => "The requested format #{options[:format]} is not supported." unless formatter        
        formatter.call(message, backtrace)
      end
      
    end
  end
end
