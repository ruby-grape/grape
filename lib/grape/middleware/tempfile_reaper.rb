# frozen_string_literal: true

module Grape
  module Middleware
    # Closes and unlinks a request's multipart tempfiles once its response is
    # closed, or as soon as an exception escapes, as Rack::TempfileReaper does.
    # Rack's multipart parser records the tempfiles it creates in
    # +rack.tempfiles+, so this looks there once the app has answered and
    # wraps the body only when there are some. Rack's reaper allocates the
    # Array and the BodyProxy for every request, and most requests upload
    # nothing. A tempfile created after the response was returned, by a body
    # that parses the upload as it is streamed, is left to garbage collection,
    # as it was before Grape reaped them.
    class TempfileReaper
      def initialize(app)
        @app = app
      end

      def call(env)
        response = begin
          @app.call(env)
        rescue Exception # rubocop:disable Lint/RescueException
          env[Rack::RACK_TEMPFILES]&.each(&:close!)
          raise
        end

        tempfiles = env[Rack::RACK_TEMPFILES]
        return response if tempfiles.nil? || tempfiles.empty?

        # A new triplet: a mounted Rack app is free to answer a frozen one.
        [response[0], response[1], Rack::BodyProxy.new(response[2]) { tempfiles.each(&:close!) }]
      end
    end
  end
end
