module Grape
  module Exceptions
    class Base < StandardError
      attr_reader :status, :message, :headers

      def initialize(args = {})
        @status = args[:status] || nil
        @message = args[:message] || nil
        @headers = args[:headers] || nil
      end

      def [](index)
        self.send(index)
      end 
    end
  end
end
