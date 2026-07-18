# frozen_string_literal: true

module Grape
  module Util
    # A branchable, inheritable settings object which can store both stackable
    # and inheritable values (see InheritableValues and StackableValues).
    class InheritableSetting
      attr_reader :route, :namespace, :namespace_inheritable, :namespace_stackable, :parent

      # Lazy-allocated; +api_class+ and +point_in_time_copies+ are rarely
      # written on most settings layers, so don't pay for a Hash/Array each.
      def api_class
        @api_class ||= {}
      end

      def point_in_time_copies
        @point_in_time_copies ||= []
      end

      # Retrieve global settings.
      def self.global
        @global ||= {}
      end

      # Clear all global settings.
      # @api private
      # @note only for testing
      def self.reset_global!
        @global = {}
      end

      # Instantiate a new settings instance, with blank values. The fresh
      # instance can then be set to inherit from an existing instance (see
      # #inherit_from).
      def initialize
        @route = {}
        @namespace = InheritableValues.new # only inheritable from a parent when
        # used with a mount, or should every API::Class be a separate namespace by default?
        @namespace_inheritable = InheritableValues.new
        @namespace_stackable = StackableValues.new
        @parent = nil
        # @api_class, @point_in_time_copies and @rescue_handler_maps stay nil until first access.
      end

      # Return the class-level global properties.
      def global
        self.class.global
      end

      # Set our inherited values to the given parent's current values. Also,
      # update the inherited values on any settings instances which were forked
      # from us.
      # @param parent [InheritableSetting]
      def inherit_from(parent)
        return if parent.nil?

        @parent = parent

        namespace_inheritable.inherited_values = parent.namespace_inheritable
        namespace_stackable.inherited_values = parent.namespace_stackable
        @route = parent.route.merge(route)

        @point_in_time_copies&.each { |cloned_one| cloned_one.inherit_from parent }
      end

      # Create a point-in-time copy of this settings instance, with clones of
      # all our values. Note that, should this instance's parent be set or
      # changed via #inherit_from, it will copy that inheritence to any copies
      # which were made.
      def point_in_time_copy
        new_setting = self.class.new
        point_in_time_copies << new_setting
        new_setting.copy_state_from(self)
        new_setting.inherit_from(parent)
        new_setting
      end

      # Resets the instance store of per-route settings.
      # @api private
      def route_end
        @route = {}
      end

      # Return a serializable hash of our values.
      def to_hash
        {
          global: global.clone,
          route: route.clone,
          namespace: namespace.to_hash,
          namespace_inheritable: namespace_inheritable.to_hash,
          namespace_stackable: namespace_stackable.to_hash,
          rescue_handlers:,
          base_only_rescue_handlers:
        }
      end

      def ==(other)
        other.is_a?(self.class) && to_hash == other.to_hash
      end
      alias eql? ==

      def namespace_stackable_with_hash(key)
        data = namespace_stackable[key]
        return if data.blank?

        data.each_with_object({}) { |value, result| result.deep_merge!(value) }
      end

      # Content negotiation registries recorded by the request/response DSL
      # (see DSL::RequestResponse): the content-type registry (+content_type+
      # and +format+), and the formatter, parser and error-formatter handler
      # maps. Each registration stacks one single-entry Hash, deep-merged on
      # read so a nested scope's registration wins; readers return nil when
      # nothing is registered. Record entries with the corresponding +add_*+
      # writer; the backing store is an internal detail.
      def content_types
        namespace_stackable_with_hash(:content_types)
      end

      def add_content_type(format, content_type)
        namespace_stackable[:content_types] = { format => content_type }
      end

      def formatters
        namespace_stackable_with_hash(:formatters)
      end

      def add_formatter(content_type, formatter)
        namespace_stackable[:formatters] = { content_type => formatter }
      end

      def parsers
        namespace_stackable_with_hash(:parsers)
      end

      def add_parser(content_type, parser)
        namespace_stackable[:parsers] = { content_type => parser }
      end

      def error_formatters
        namespace_stackable_with_hash(:error_formatters)
      end

      def add_error_formatter(format, formatter)
        namespace_stackable[:error_formatters] = { format => formatter }
      end

      # Rescue-handler maps registered by +rescue_from+, keyed by exception
      # class and merged so a nested scope's handler wins. Record them with
      # #add_rescue_handlers; the backing store is an internal detail.
      def rescue_handlers
        merged_rescue_handlers(:rescue_handlers)
      end

      def base_only_rescue_handlers
        merged_rescue_handlers(:base_only_rescue_handlers)
      end

      # An exception class registered twice in the same scope keeps its first
      # handler, and keeps the position it was first registered at.
      def add_rescue_handlers(mapping, subclasses:)
        @rescue_handler_maps ||= {}
        own = (@rescue_handler_maps[subclasses ? :rescue_handlers : :base_only_rescue_handlers] ||= {})
        own.merge!(mapping) { |_klass, registered, _new| registered }
      end

      protected

      # This scope's own +rescue_from+ registrations, before inheritance:
      # {rescue_handlers: {klass => handler}, base_only_rescue_handlers: {...}}.
      attr_reader :rescue_handler_maps

      # Nearest scope's handlers first: Middleware::Error scans with +find+,
      # so a nested scope's registrations must precede inherited ones even
      # when an outer scope registered a more specific class.
      def merged_rescue_handlers(key)
        inherited = parent&.merged_rescue_handlers(key)
        own = @rescue_handler_maps&.[](key)
        return inherited unless own

        own.merge(inherited || {}) { |_klass, nearer, _inherited| nearer }
      end

      # Used by +point_in_time_copy+ to populate a freshly-built instance
      # with cloned state from another instance of the same class.
      def copy_state_from(source)
        @namespace = source.namespace.clone
        @namespace_inheritable = source.namespace_inheritable.clone
        @namespace_stackable = source.namespace_stackable.clone
        @rescue_handler_maps = source.rescue_handler_maps&.dup
        @route = source.route.clone
        @api_class = source.api_class
      end
    end
  end
end
