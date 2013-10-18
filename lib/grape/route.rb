module Grape

  # A compiled route for inspection.
  class Route

    def initialize(options = {})
      @options = options || {}
    end

    def method_missing(method_id, *arguments)
      match = /route_([_a-zA-Z]\w*)/.match(method_id.to_s)
      if match
        @options[match.captures.last.to_sym]
      else
        super
      end
    end

    def to_s
      "version=#{route_version}, method=#{route_method}, path=#{route_path}"
    end

    private

    def to_ary
      nil
    end

  end
end
