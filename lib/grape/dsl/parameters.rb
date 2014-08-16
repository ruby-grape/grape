require 'active_support/concern'

module Grape
  module DSL
    module Parameters
      extend ActiveSupport::Concern

      def use(*names)
        named_params = @api.settings[:named_params] || {}
        options = names.last.is_a?(Hash) ? names.pop : {}
        names.each do |name|
          params_block = named_params.fetch(name) do
            raise "Params :#{name} not found!"
          end
          instance_exec(options, &params_block)
        end
      end
      alias_method :use_scope, :use
      alias_method :includes, :use

      def requires(*attrs, &block)
        orig_attrs = attrs.clone

        opts = attrs.last.is_a?(Hash) ? attrs.pop : nil

        if opts && opts[:using]
          require_required_and_optional_fields(attrs.first, opts)
        else
          validate_attributes(attrs, opts, &block)

          block_given? ? new_scope(orig_attrs, &block) :
              push_declared_params(attrs)
        end
      end

      def optional(*attrs, &block)
        orig_attrs = attrs

        validations = {}
        validations.merge!(attrs.pop) if attrs.last.is_a?(Hash)
        validations[:type] ||= Array if block_given?
        validates(attrs, validations)

        block_given? ? new_scope(orig_attrs, true, &block) :
            push_declared_params(attrs)
      end

      def mutually_exclusive(*attrs)
        validates(attrs, mutual_exclusion: true)
      end

      def exactly_one_of(*attrs)
        validates(attrs, exactly_one_of: true)
      end

      def at_least_one_of(*attrs)
        validates(attrs, at_least_one_of: true)
      end

      def group(*attrs, &block)
        requires(*attrs, &block)
      end

      def params(params)
        params = @parent.params(params) if @parent
        if @element
          if params.is_a?(Array)
            params = params.flat_map { |el| el[@element] || {} }
          elsif params.is_a?(Hash)
            params = params[@element] || {}
          else
            params = {}
          end
        end
        params
      end
    end
  end
end
