module Grape
  class Namespace
    attr_reader :space, :options

    # options:
    #   requirements: a hash
    def initialize(space, options = {})
      @space, @options = space.to_s, options
    end

    def requirements
      options[:requirements] || {}
    end

  end
end
