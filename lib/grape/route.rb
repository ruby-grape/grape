module Grape
  # A compiled route for inspection.
  class Route
    attr_reader :helper_names, :helper_arguments

    def initialize(options = {})
      @options = options || {}
      @helper_names = []
      @helper_arguments = required_helper_segments
      define_path_helpers
    end

    def define_path_helpers
      route_versions.each do |version|
        opts = { version: version }
        method_name = path_helper_name(opts)
        @helper_names << method_name
        define_path_helper(method_name, opts)
      end
    end

    def define_path_helper(method_name, predefined_opts)
      method_body = <<-RUBY
        def #{method_name}(opts = {})
          opts = #{predefined_opts}.merge(opts)
          opts = HashWithIndifferentAccess.new(opts)

          content_type = opts.delete(:format)
          path = '/' + path_segments_with_values(opts).join('/')
          extension = content_type ? '.' + content_type : ''

          path + extension
        end
      RUBY
      instance_eval method_body
    end

    def route_versions
      if route_version
        route_version.split('|')
      else
        [nil]
      end
    end

    def path_helper_name(opts = {})
      segments = path_segments_with_values(opts)

      name = if segments.empty?
               'root'
             else
               segments.join('_')
             end
      name + '_path'
    end

    def segment_to_value(segment, opts = {})
      updated_options = @options.merge(opts)
      options = HashWithIndifferentAccess.new(updated_options)

      if dynamic_segment?(segment)
        key = segment.slice(1..-1)
        options[key]
      else
        segment
      end
    end

    def path_segments_with_values(opts)
      segments = path_segments.map { |s| segment_to_value(s, opts) }
      segments.reject(&:blank?)
    end

    def path_segments
      pattern = /\(\/?\.:format\)|\/|\*/
      route_path.split(pattern).reject(&:blank?)
    end

    def dynamic_path_segments
      segments = path_segments.select do |segment|
        dynamic_segment?(segment)
      end
      segments.map { |s| s.slice(1..-1) }
    end

    def dynamic_segment?(segment)
      segment.start_with?(':')
    end

    def required_helper_segments
      segments_in_options = dynamic_path_segments.select do |segment|
        @options[segment.to_sym]
      end
      dynamic_path_segments - segments_in_options
    end

    def optional_segments
      ['format']
    end

    def uses_segments_in_path_helper?(segments)
      requested = segments - optional_segments
      required = required_helper_segments

      if requested.empty? && required.empty?
        true
      else
        requested.all? do |segment|
          required.include?(segment)
        end
      end
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
