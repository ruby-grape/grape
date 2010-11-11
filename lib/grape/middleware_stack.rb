require 'grape'

module Grape
  class MiddlewareStack
    attr_reader :stack
    
    def initialize
      @stack = []
    end
    
    # Add a new middleware to the stack. Syntax
    # is identical to normal middleware <tt>#use</tt>
    # functionality.
    #
    # @param [Class] klass The middleware class.
    def use(klass, *args)
      if index = @stack.index(@stack.find{|a| a.first == klass})
        @stack[index] = [klass, *args]
      else
        @stack << [klass, *args]
      end
    end
    
    # Apply this middleware stack to a
    # Rack application.
    def to_app(app)
      b = Rack::Builder.new
      for middleware in stack
        b.use *middleware
      end
      b.run app
      b.to_app
    end
  end
end