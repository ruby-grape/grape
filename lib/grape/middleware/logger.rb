# This Middleware is not loaded by grape by default.
# If you intend to use it you must first:
#   require 'grape/middleware/logger'
# See the spec for examples.
#
require 'grape/middleware/globals'

module Grape
  module Middleware
    class Logger < Globals

      def before
        super
        logger.info "[api] Requested#{request_log}" if !request_log.blank?
        logger.info "[api] HEADERS: #{@env['grape.request.headers']}" if !@env['grape.request.headers'].blank?
        logger.info "[api] PARAMS: #{@env['grape.request.params']}" if !@env['grape.request.params'].blank?
      end

      # Example of what you might do in a subclass in an after hook:
      #   def after
      #     response_body = JSON.parse(response.body.first)
      #     if response_body.is_a?(Hash)
      #       logger.debug "[api] RespType: #{response_body['response_type']}" unless response_body['response_type'].blank?
      #       logger.debug "[api] Response: #{response_body['response']}" unless response_body['response'].blank?
      #       logger.debug "[api] Backtrace:\n#{response_body['backtrace'].join("\n")}" if response_body['backtrace'] && response_body['backtrace'].any?
      #     end
      #     super
      #   end

      private

      # Override in a subclass to customize the logger (not affected by setting the logger helper in Grape::API)
      #   def logger
      #     @logger ||= Rails.logger # as an example
      #   end
      def logger
        @logger ||= Logger.new(STDOUT)
      end

      def request_log
        @request_log ||= begin
          res = ''
          res << " #{request_log_data}" if !request_log_data.blank?
          res
        end
      end

      def request_log_data
        rld = {}

        x_org = env['HTTP_X_ORGANIZATION']

        rld[:user_id] = current_user.id if current_user
        rld[:x_organization] = x_org if x_org

        rld
      end

      # Override this method in a subclass and mount the subclass
      # For example with Devise & Warden:
      #   def current_user
      #     @warden_user_for_log ||= begin
      #       woo = env['warden'].instance_variable_get(:'@users')
      #       woo[:user] if woo
      #     end
      #   end
      # Also if Warden is later in your Rack Middleware stack
      #   then you can only render the current user data in the after hook, not the before hook.
      def current_user
        false
      end
    end
  end
end
