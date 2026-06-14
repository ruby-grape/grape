# frozen_string_literal: true

module Grape
  # Since multi_xml 0.9.0 the canonical constant is MultiXML; MultiXml is a
  # deprecated alias (removed in v1.0) that warns on use. Prefer MultiXML so
  # Grape::Xml.parse doesn't trip the deprecation, falling back to the legacy
  # constant and then ActiveSupport::XmlMini.
  # https://github.com/sferik/multi_xml/blob/v0.9.1/CHANGELOG.md
  if defined?(::MultiXML)
    Xml = ::MultiXML
  elsif defined?(::MultiXml)
    Xml = ::MultiXml
  else
    Xml = ::ActiveSupport::XmlMini
    Xml::ParseError = StandardError
  end
end
