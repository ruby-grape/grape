# frozen_string_literal: true

module Grape
  module Util
    if defined?(::MultiXml)
      Xml = ::MultiXml
    else
      Xml = ::ActiveSupport::XmlMini
      Xml::ParseError = StandardError
    end
  end
end
