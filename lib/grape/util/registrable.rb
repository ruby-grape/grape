module Grape
  module Registrable
    def default_elements
      @default_elements ||= {}
    end

    def register(format, element)
      default_elements[format] = element unless default_elements[format]
    end
  end
end
