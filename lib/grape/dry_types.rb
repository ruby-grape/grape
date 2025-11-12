# frozen_string_literal: true

module Grape
  module DryTypes
    # https://dry-rb.org/gems/dry-types/main/getting-started/
    # limit to what Grape is using
    include Dry.Types(:params, :coercible, :strict)

    class StrictCache < Grape::Util::Cache
      MAPPING = {
        Grape::API::Boolean => DryTypes::Strict::Bool,
        BigDecimal => DryTypes::Strict::Decimal,
        Numeric => DryTypes::Strict::Integer | DryTypes::Strict::Float | DryTypes::Strict::Decimal,
        TrueClass => DryTypes::Strict::Bool.constrained(eql: true),
        FalseClass => DryTypes::Strict::Bool.constrained(eql: false)
      }.freeze

      def initialize
        super
        @cache = Hash.new do |h, strict_type|
          h[strict_type] = MAPPING.fetch(strict_type) do
            DryTypes.wrapped_dry_types_const_get(DryTypes::Strict, strict_type)
          end
        end
      end
    end

    class ParamsCache < Grape::Util::Cache
      MAPPING = {
        Grape::API::Boolean => DryTypes::Params::Bool,
        BigDecimal => DryTypes::Params::Decimal,
        Numeric => DryTypes::Params::Integer | DryTypes::Params::Float | DryTypes::Params::Decimal,
        TrueClass => DryTypes::Params::Bool.constrained(eql: true),
        FalseClass => DryTypes::Params::Bool.constrained(eql: false),
        String => DryTypes::Coercible::String
      }.freeze

      def initialize
        super
        @cache = Hash.new do |h, params_type|
          h[params_type] = MAPPING.fetch(params_type) do
            DryTypes.wrapped_dry_types_const_get(DryTypes::Params, params_type)
          end
        end
      end
    end

    def self.wrapped_dry_types_const_get(dry_type, type)
      dry_type.const_get(type.name, false)
    rescue NameError
      raise ArgumentError, "type #{type} should support coercion via `[]`" unless type.respond_to?(:[])
    end
  end
end
