require 'grape/exceptions/base'

module Grape
  module Exceptions
    class Validations < Grape::Exceptions::Base
      attr_accessor :errors

      def initialize(args = {})
        @errors = args[:errors]
        errors_as_sentence = @errors.collect { |e| e.message }.join(', ')
        super message: errors_as_sentence, status: 400
      end
    end
  end
end
