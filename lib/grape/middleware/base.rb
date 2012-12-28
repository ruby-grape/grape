require 'active_support/ordered_hash'
require 'active_support/core_ext/hash/indifferent_access'
require 'multi_json'
require 'multi_xml'

module Grape
  module Middleware
    class Base
      # Content types are listed in order of preference.
      CONTENT_TYPES = ActiveSupport::OrderedHash[
        :xml,  'application/xml',
        :serializable_hash, 'application/json',
        :json, 'application/json',
        :atom, 'application/atom+xml',
        :rss,  'application/rss+xml',
        :txt,  'text/plain',
      ]

      attr_reader :app, :env, :options

      # @param [Rack Application] app The standard argument for a Rack middleware.
      # @param [Hash] options A hash of options, simply stored for use by subclasses.
      def initialize(app, options = {})
        @app = app
        @options = default_options.merge(options)
      end

      def default_options
        {}
      end

      def call(env)
        dup.call!(env)
      end

      def call!(env)
        @env = env
        before
        @app_response = @app.call(@env)
        after || @app_response
      end

      # @abstract
      # Called before the application is called in the middleware lifecycle.
      def before; end
      # @abstract
      # Called after the application is called in the middleware lifecycle.
      # @return [Response, nil] a Rack SPEC response or nil to call the application afterwards.
      def after; end

      def request
        Rack::Request.new(self.env)
      end

      def response
        Rack::Response.new(@app_response)
      end

      def content_type_for(format)
        HashWithIndifferentAccess.new(content_types)[format]
      end

      def content_types
        options[:content_types] || CONTENT_TYPES
      end

      def content_type
        content_type_for(env['api.format'] || options[:format]) || 'text/html'
      end

      def mime_types
        content_types.invert
      end

    end
  end
end
