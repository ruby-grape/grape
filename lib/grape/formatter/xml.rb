module Grape
  module Formatter
    module Xml
      class << self

        def call(object)
          object.respond_to?(:to_xml) ? object.to_xml : object.to_s
        end

      end
    end
  end
end
