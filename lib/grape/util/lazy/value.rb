# frozen_string_literal: true

module Grape
  module Util
    module Lazy
      # A read of a mount-time configuration, taken before there is one to read.
      #
      # A remountable API reads its configuration while its own class body runs,
      # long before anybody mounts it and supplies one:
      #
      #   class Votes < Grape::API
      #     get configuration[:path] do
      #       configuration[:response]
      #     end
      #   end
      #
      #   Root.mount Votes, with: { path: 'votes', response: '10 votes' }
      #
      # +configuration[:path]+ cannot answer 'votes' yet, so it answers with a
      # Value instead: the configuration it was read from, plus the path of keys
      # taken to reach it. Grape records the +get+ step unevaluated and replays
      # it once per mount, where {#evaluate_from} walks that same path through
      # the configuration that mount supplied.
      #
      # Reads chain, so +configuration[:db][:host]+ and
      # +configuration[:hosts][0]+ are Values holding a two-key path.
      class Value < Base
        attr_reader :path

        def initialize(config, path = [])
          super()
          @config = config
          @path = path
        end

        # @return [Value] the same read, one key deeper.
        def [](key)
          Value.new(@config, @path + [key])
        end

        # Writes back to the configuration this was read from, backing
        # <tt>API.configure { |config| config[:key] = value }</tt>.
        def []=(key, value)
          evaluate[key] = value
        end

        # @return [Object] what this path holds in the configuration it was read
        #   from, or +nil+ where the path leads nowhere - which is every path on
        #   a base instance, whose configuration stays empty until it is mounted.
        def evaluate
          at(@path)
        end

        # @return [Object] what this path holds in +configuration+, the
        #   configuration of the instance being mounted right now.
        def evaluate_from(configuration)
          configuration.at(@path)
        end

        protected

        def at(keys)
          keys.reduce(@config) do |node, key|
            break nil unless node.is_a?(Hash) || node.is_a?(Array)

            node[key]
          end
        end
      end
    end
  end
end
