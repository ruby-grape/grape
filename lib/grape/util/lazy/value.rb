# frozen_string_literal: true

module Grape
  module Util
    module Lazy
      class Value < Base
        attr_reader :access_keys

        def initialize(value, access_keys = [])
          super()
          @value = value
          @access_keys = access_keys
        end

        def evaluate_from(configuration)
          matching_lazy_value = configuration.fetch(@access_keys)
          matching_lazy_value.evaluate
        end

        def evaluate
          @value
        end

        def reached_by(parent_access_keys, access_key)
          @access_keys = parent_access_keys + [access_key]
          self
        end
      end
    end
  end
end
