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

      def compose_message(key, **)
        short_message = translate_message(key, **)
        return short_message unless short_message.is_a?(Hash)

        MESSAGE_STEPS.filter_map do |step, label|
          detail = translate_message(:"#{key}.#{step}", **)
          "\n#{label}:\n  #{detail}" if detail.present?
        end.join
      end

      def translate_message(translation_key, **)
        case translation_key
        when Symbol
          translate(translation_key, **)
        when Hash
          translation_key => { key:, **opts }
          translate(key, **opts)
        when Proc
          translation_key.call
        else
          translation_key
        end
      end
    end
  end
end
