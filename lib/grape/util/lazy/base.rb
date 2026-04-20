# frozen_string_literal: true

module Grape
  module Util
    module Lazy
      # Abstract parent for lazy wrappers used by the remount/configuration
      # machinery. Call sites can type-check with +is_a?(Grape::Util::Lazy::Base)+
      # instead of enumerating the concrete subclasses.
      class Base
        def to_s
          evaluate.to_s
        end
      end
    end
  end
end
