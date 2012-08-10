require 'grape/middleware/base'
require 'multi_json'

module Grape
  module Middleware
    class Error < Base
      include Formats

      def default_options
      { 
        :default_status => 403, # default status returned on error
        :default_message => "",
        :format => :txt,
        :formatters => {},
        :rescue_all => false, # true to rescue all exceptions        
        :rescue_options => { :backtrace => false }, # true to display backtrace
        :rescue_handlers => {}, # rescue handler blocks
        :rescued_errors => []
      }
      end

      def encode_json(message, backtrace)
        result = message.is_a?(Hash) ? message : { :error => message }
        if (options[:rescue_options] || {})[:backtrace] && backtrace && ! backtrace.empty?
          result = result.merge({ :backtrace => backtrace })
        end
        MultiJson.dump(result)
      end
      
      def encode_txt(message, backtrace)
        result = message.is_a?(Hash) ? MultiJson.dump(message) : message
        if (options[:rescue_options] || {})[:backtrace] && backtrace && ! backtrace.empty?
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
          is_rescuable = rescuable?(e.class)
          if e.is_a?(Grape::Exceptions::Base) && !is_rescuable
            handler = lambda { error_response(e) }
          else
            raise unless is_rescuable
            handler = options[:rescue_handlers][e.class] || options[:rescue_handlers][:all]
          end
          handler.nil? ? handle_error(e) : self.instance_exec(e, &handler)
        end
      end

      def rescuable?(klass)
        options[:rescue_all] || (options[:rescued_errors] || []).include?(klass)
      end
      
      def handle_error(e)
        error_response({ :message => e.message, :backtrace => e.backtrace })
      end
      
      def error_response(error = {})
        status = error[:status] || options[:default_status]
        message = error[:message] || options[:default_message]
        headers = {'Content-Type' => content_type}
        headers.merge!(error[:headers]) if error[:headers].is_a?(Hash)
        backtrace = error[:backtrace] || []
        rack_response(format_message(message, backtrace, status), status, headers)
      end

      def rack_response(message, status = options[:default_status], headers = { 'Content-Type' => content_type })
        Rack::Response.new([ message ], status, headers).finish
      end
            
      def format_message(message, backtrace, status)
        formatter = formatter_for(options[:format])
        throw :error, :status => 406, :message => "The requested format #{options[:format]} is not supported." unless formatter
        formatter.call(message, backtrace)
      end
      
    end
  end
end
