module Grape
  # A compiled route for inspection.
  class Route
    # @api private
    def initialize(options = {})
      @options = options || {}
    end

    # @api private
    def method_missing(method_id, *arguments)
      match = /route_([_a-zA-Z]\w*)/.match(method_id.to_s)
      if match
        @options[match.captures.last.to_sym]
      else
        super
      end
    end

    # Generate a short, human-readable representation of this route.
    def to_s
      "version=#{route_version}, method=#{route_method}, path=#{route_path}"
    end

    private

    # This is defined so that certain Ruby methods which attempt to call #to_ary
    # on objects, e.g. Array#join, will not hit #method_missing.
    def to_ary
      nil
    end
  end
end
