module Grape
  class Protection
    attr_reader :env
    def initialize(endpoint, options = {}, &block)
      @endpoint = endpoint
      @env = endpoint.env
      @options = options
      @protection_block = block
    end

    delegate :params, :headers, :current_user, :to => :@endpoint

    def protect
      Strategy.from(self, protect_strategy).run
    end

    def protect_strategy
      @options[:protect_strategy]
    end

    def run_protection_block
      env['api.current_user'] = instance_eval(&@protection_block)
    end

    class Strategy
      attr_reader :protection
      def initialize(protection = nil)
        @protection = protection
      end

      def run
        protection.run_protection_block
      end

      def self.from(protection, strategy_value)
        case strategy_value
        when true
          ForceStrategy.new(protection)
        when false
          SkipStrategy.new
        when :optional
          Strategy.new(protection)
        else
          raise 'the valid value of protect is true, false, optional.'
        end
      end
    end

    class ForceStrategy < Strategy
      def run
        super
        throw :error, :status => 401, :message => "API Authorization Failed." unless protection.current_user
      end
    end

    class SkipStrategy < Strategy
      def run
        # do nothing
      end
    end
  end

end
