module Grape
  module Validations
    module Types
      # +Virtus::Attribute+ implementation for parameters
      # that are multipart file objects. Actual handling
      # of these objects is provided by +Rack::Request+;
      # this class is here only to assert that rack's
      # handling has succeeded, and to prevent virtus
      # from interfering.
      class File < Virtus::Attribute
        def coerce(input)
          # Processing of multipart file objects
          # is already taken care of by Rack::Request.
          # Nothing to do here.
          input
        end

        def value_coerced?(value)
          # Rack::Request creates a Hash with filename,
          # content type and an IO object. Grape wraps that
          # using hashie for convenience. Do a bit of basic
          # duck-typing.
          value.is_a?(Hashie::Mash) && value.key?(:tempfile)
        end
      end
    end
  end
end
