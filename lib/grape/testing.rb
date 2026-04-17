# frozen_string_literal: true

module Grape
  module Testing
    module RunBeforeEach
      def run
        self.class.run_before_each(self)
        super
      end
    end

    module ClassMethods
      def before_each(&block)
        raise ArgumentError, 'a block is required' unless block

        @before_each ||= []
        @before_each << block
      end

      def reset_before_each
        @before_each&.clear
      end

      def run_before_each(endpoint)
        superclass.run_before_each(endpoint) unless self == Grape::Endpoint
        @before_each&.each { |blk| blk.call(endpoint) }
      end
    end

    Grape::Endpoint.prepend(RunBeforeEach)
    Grape::Endpoint.extend(ClassMethods)
  end
end
