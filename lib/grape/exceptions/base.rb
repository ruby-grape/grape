module Grape
  module Exceptions
    class Base < StandardError

      BASE_MESSAGES_KEY = 'grape.errors.messages'
      BASE_ATTRIBUTES_KEY = 'grape.errors.attributes'

      attr_reader :status, :message, :headers

      def initialize(args = {})
        @status = args[:status] || nil
        @message = args[:message] || nil
        @headers = args[:headers] || nil
      end

      def [](index)
        self.send(index)
      end

      protected

      def translate_attribute(key, options = {})
        translate("#{BASE_ATTRIBUTES_KEY}.#{key}", { :default => key }.merge(options))
      end

      def translate_message(key, options = {})
        translate("#{BASE_MESSAGES_KEY}.#{key}", options)
      end

      def translate(key, options = {})
        ::I18n.translate(key, options)
      end

    end
  end
end
