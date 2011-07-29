module Grape

  # A compiled route for inspection.
  class Route
  
    attr_reader :prefix
    attr_reader :version
    attr_reader :namespace
    attr_reader :method
    attr_reader :path
    
    def initialize(prefix, version, namespace, method, path)
      @prefix = prefix
      @version = version
      @namespace = namespace
      @method = method
      @path = path
    end
    
    def to_s
      "#{method} #{path}"
    end
    
  end
end
