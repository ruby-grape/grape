# frozen_string_literal: true

module Grape
  class Endpoint
    # Remove in 5.0. Before 4.2.0 a route reached only the helpers declared
    # above it in its scope, the ones its settings copy holds. Where one
    # declared below redefines a method of those, the route now answers with
    # the later definition, and nothing else would tell.
    module RedefinedHelpersWarning
      module_function

      # +above+ are the helpers the route reached before 4.2.0, +helpers+ all
      # those it reaches now, and +composed+ the module they make up.
      def call(routes:, above:, helpers:, composed:)
        below = helpers - above
        return if above.empty? || below.empty?

        before = Module.new { above.each { |mod_to_include| include mod_to_include } }
        names = redefined_names(below, before, composed)
        return if names.empty?

        names.each do |name|
          warn(
            "Grape: helper `#{name}` is defined again below #{route_names(routes)} in the same scope, so since 4.2.0 " \
            'that route answers with the later definition (see UPGRADING.md). ' \
            'Rename one of them, or declare the route in its own namespace.'
          )
        end
      end

      def route_names(routes)
        routes.map { |route| "#{route.request_method} #{route.origin}" }.uniq.join(', ')
      end

      # The methods of +below+ that change what +before+ answered.
      def redefined_names(below, before, composed)
        below.flat_map { |mod| mod.instance_methods + mod.private_instance_methods }.uniq.select do |name|
          (before.method_defined?(name) || before.private_method_defined?(name)) &&
            before.instance_method(name).owner != composed.instance_method(name).owner
        end
      end
    end
  end
end
