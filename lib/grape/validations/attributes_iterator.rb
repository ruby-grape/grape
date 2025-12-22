# frozen_string_literal: true

module Grape
  module Validations
    class AttributesIterator
      include Enumerable

      attr_reader :scope

      def initialize(validator, scope, params)
        @scope = scope
        @attrs = validator.attrs
        @original_params = scope.params(params)
        @params = Array.wrap(@original_params)
      end

      def each(&)
        do_each(@params, &) # because we need recursion for nested arrays
      end

      private

      def do_each(params_to_process, parent_indicies = [], &block)
        @scope.reset_index # gets updated depending on the size of params_to_process
        params_to_process.each_with_index do |resource_params, index|
          # when we get arrays of arrays it means that target element located inside array
          # we need this because we want to know parent arrays indicies
          if resource_params.is_a?(Array)
            do_each(resource_params, [index] + parent_indicies, &block)
            next
          end

          if @scope.type == Array
            next unless @original_params.is_a?(Array) # do not validate content of array if it isn't array

            # fill current and parent scopes with correct array indicies
            parent_scope = @scope.parent
            parent_indicies.each do |parent_index|
              parent_scope.index = parent_index
              parent_scope = parent_scope.parent
            end
            @scope.index = index
          end

          yield_attributes(resource_params, @attrs, &block)
        end
      end

      def yield_attributes(_resource_params, _attrs)
        raise NotImplementedError
      end

      # This is a special case so that we can ignore tree's where option
      # values are missing lower down. Unfortunately we can remove this
      # are the parameter parsing stage as they are required to ensure
      # the correct indexing is maintained
      def skip?(val)
        val == Grape::DSL::Parameters::EmptyOptionalValue
      end
    end
  end
end
