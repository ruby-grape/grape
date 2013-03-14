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

    def self.joined_space(settings)
      settings.gather(:namespace).map(&:space).join("/")
    end

    def self.joined_space_path(settings)
      Rack::Mount::Utils.normalize_path(joined_space(settings))
    end

  end
end
