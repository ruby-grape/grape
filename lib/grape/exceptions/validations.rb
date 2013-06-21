require 'grape/exceptions/base'

module Grape
  module Exceptions
    class Validations < Grape::Exceptions::Base
      attr_accessor :errors

      def initialize(args = {})
        @errors = args[:errors]
        super message: @errors.collect { |e| e.message }.join(', '), status: 400
      end
    end
  end
end
