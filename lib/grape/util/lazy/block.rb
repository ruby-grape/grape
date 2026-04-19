# frozen_string_literal: true

module Grape
  module Util
    module Lazy
      class Block < Base
        def initialize(&new_block)
          super()
          @block = new_block
        end

        def evaluate_from(configuration)
          @block.call(configuration)
        end

        def evaluate
          @block.call({})
        end
      end
    end
  end
end
