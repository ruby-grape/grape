# frozen_string_literal: true

module Grape
  # A container for endpoints or other namespaces, which allows for both
  # logical grouping of endpoints as well as sharing common configuration.
  # May also be referred to as group, segment, or resource.
  class Namespace
    attr_reader :space, :requirements, :options

    # @param space [String] the name of this namespace
    # @param options [Hash] options hash
    # @option options :requirements [Hash] param-regex pairs, all of which must
    #   be met by a request's params for all endpoints in this namespace, or
    #   validation will fail and return a 422.
    def initialize(space, requirements: nil, **options)
      @space = space.to_s
      @requirements = requirements
      @options = options
    end

    # (see ::joined_space_path)
    def self.joined_space(settings)
      settings&.map(&:space)
    end

    def eql?(other)
      other.class == self.class &&
        other.space == space &&
        other.requirements == requirements &&
        other.options == options
    end
    alias == eql?

    def hash
      [self.class, space, requirements, options].hash
    end

    # Join the namespaces from a list of settings to create a path prefix.
    # @param settings [Array] list of Grape::Util::InheritableSettings.
    def self.joined_space_path(settings)
      JoinedSpaceCache[joined_space(settings)]
    end

    class JoinedSpaceCache < Grape::Util::Cache
      def initialize
        super
        @cache = Hash.new do |h, joined_space|
          h[joined_space] = Grape::Router.normalize_path(joined_space.join('/'))
        end
      end
    end
  end
end
