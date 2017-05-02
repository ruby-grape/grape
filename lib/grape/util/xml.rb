begin
  require 'multi_xml'
rescue LoadError
end

module Grape
  if Object.const_defined? :MultiXml
    Xml = ::MultiXml
  else
    Xml = ::ActiveSupport::XmlMini
    Xml::ParseError = StandardError
  end
end
