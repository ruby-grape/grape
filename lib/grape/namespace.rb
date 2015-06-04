module Grape
  class Namespace
    attr_reader :space, :options

    # options:
    #   requirements: a hash
    def initialize(space, options = {})
      @space = space.to_s
      @options = options
    end

    def requirements
      options[:requirements] || {}
    end

    def self.joined_space(settings)
      (settings || []).map(&:space).join('/')
    end

    def self.joined_space_path(settings)
      Rack::Mount::Utils.normalize_path(joined_space(settings))
    end
  end
end
