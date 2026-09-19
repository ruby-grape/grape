# frozen_string_literal: true

module Grape
  module Middleware
    module Auth
      StrategyInfo = Struct.new(:auth_class, :settings_fetcher) do
        def create(app, options, &)
          strategy_args = settings_fetcher.call(options)

          auth_class.new(app, *strategy_args, &)
        end
      end
    end
  end
end
