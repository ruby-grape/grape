# frozen_string_literal: true

module Grape
  if defined?(::MultiXml)
    Xml = ::MultiXml
  else
    Xml = ::ActiveSupport::XmlMini
    Xml::ParseError = StandardError
  end
end
