module Grape
  module Util
    class InheritableSetting
      attr_accessor :route, :api_class, :namespace, :namespace_inheritable, :namespace_stackable
      attr_accessor :parent, :point_in_time_copies

      def self.global
        @global ||= {}
      end

      def self.reset_global! # only for testing
        @global = {}
      end

      def initialize
        self.route = {}
        self.api_class = {}
        self.namespace = InheritableValues.new # only inheritable from a parent when
        # used with a mount, or should every API::Class be a seperate namespace by default?
        self.namespace_inheritable = InheritableValues.new
        self.namespace_stackable = StackableValues.new

        self.point_in_time_copies = []

        self.parent = nil
      end

      def global
        self.class.global
      end

      def inherit_from(parent)
        return if parent.nil?

        self.parent = parent

        namespace_inheritable.inherited_values = parent.namespace_inheritable
        namespace_stackable.inherited_values = parent.namespace_stackable
        self.route = parent.route.merge(route)

        point_in_time_copies.map { |cloned_one| cloned_one.inherit_from parent }
      end

      def point_in_time_copy
        self.class.new.tap do |new_setting|
          point_in_time_copies << new_setting
          new_setting.point_in_time_copies = []

          new_setting.namespace = namespace.clone
          new_setting.namespace_inheritable = namespace_inheritable.clone
          new_setting.namespace_stackable = namespace_stackable.clone
          new_setting.route = route.clone
          new_setting.api_class = api_class

          new_setting.inherit_from(parent)
        end
      end

      def route_end
        @route = {}
      end

      def to_hash
        {
          global: global.clone,
          route: route.clone,
          namespace: namespace.to_hash,
          namespace_inheritable: namespace_inheritable.to_hash,
          namespace_stackable: namespace_stackable.to_hash
        }
      end
    end
  end
end
