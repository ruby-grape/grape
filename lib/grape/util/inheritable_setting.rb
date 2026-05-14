# frozen_string_literal: true

module Grape
  module Util
    # A branchable, inheritable settings object which can store both stackable
    # and inheritable values (see InheritableValues and StackableValues).
    class InheritableSetting
      attr_reader :route, :api_class, :namespace, :namespace_inheritable, :namespace_stackable, :namespace_reverse_stackable, :parent, :point_in_time_copies

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
        @api_class = {}
        @namespace = InheritableValues.new # only inheritable from a parent when
        # used with a mount, or should every API::Class be a separate namespace by default?
        @namespace_inheritable = InheritableValues.new
        @namespace_stackable = StackableValues.new
        @namespace_reverse_stackable = ReverseStackableValues.new
        @point_in_time_copies = []
        @parent = nil
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
        namespace_reverse_stackable.inherited_values = parent.namespace_reverse_stackable
        @route = parent.route.merge(route)

        point_in_time_copies.each { |cloned_one| cloned_one.inherit_from parent }
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
          namespace_reverse_stackable: namespace_reverse_stackable.to_hash
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

      protected

      # Used by +point_in_time_copy+ to populate a freshly-built instance
      # with cloned state from another instance of the same class.
      def copy_state_from(source)
        @namespace = source.namespace.clone
        @namespace_inheritable = source.namespace_inheritable.clone
        @namespace_stackable = source.namespace_stackable.clone
        @namespace_reverse_stackable = source.namespace_reverse_stackable.clone
        @route = source.route.clone
        @api_class = source.api_class
      end
    end
  end
end
