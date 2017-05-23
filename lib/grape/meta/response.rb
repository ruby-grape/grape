module Grape
  module Meta
    class Response
      def initialize(entity_class, status = 200, description = nil)
        @entity_class = entity
        @status = status
        @description = description
      end
    end
  end
end
