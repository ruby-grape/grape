# frozen_string_literal: true

module Grape
  module Exceptions
    class Base < StandardError
      include Grape::Util::Translation

      MESSAGE_STEPS = %w[problem summary resolution].to_h { |s| [s, s.capitalize] }.freeze

      attr_reader :status, :headers

      def initialize(status: nil, message: nil, headers: nil)
        super(message)

        @status  = status
        @headers = headers
      end

      def [](index)
        __send__ index
      end

      private

      # TODO: translate attribute first
      # if BASE_ATTRIBUTES_KEY.key respond to a string message, then short_message is returned
      # if BASE_ATTRIBUTES_KEY.key respond to a Hash, means it may have problem , summary and resolution
      def compose_message(key, **)
        short_message = translate_message(key, **)
        return short_message unless short_message.is_a?(Hash)

        MESSAGE_STEPS.filter_map do |step, label|
          detail = translate_message(:"#{key}.#{step}", **)
          "\n#{label}:\n  #{detail}" if detail.present?
        end.join
      end

      def translate_attributes(keys, **)
        keys.map do |key|
          translate(key, scope: 'grape.errors.attributes', default: key.to_s, **)
        end.join(', ')
      end

      def translate_message(translation_key, **)
        case translation_key
        when Symbol
          translate(translation_key, scope: 'grape.errors.messages', **)
        when Hash
          translate(translation_key[:key], scope: 'grape.errors.messages', **translation_key.except(:key))
        when Proc
          translation_key.call
        else
          translation_key
        end
      end
    end
  end
end
