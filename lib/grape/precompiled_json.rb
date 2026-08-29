# frozen_string_literal: true

module Grape
  # Marks a body as JSON that has already been rendered, so the JSON formatters
  # serve it verbatim instead of encoding it a second time.
  #
  # +Grape::Formatter::Json+ calls +to_json+ on whatever the endpoint returned, so a
  # String holding pre-rendered JSON — a blob cached in Redis, a +json_agg+ column read
  # straight from Postgres, output from another serializer — comes back encoded twice:
  #
  #   '{"a":1}'  =>  "\"{\\\"a\\\":1}\""
  #
  # Wrapping the body opts that one response out of encoding:
  #
  #   get '/cached' do
  #     body Grape::PrecompiledJson.new(Rails.cache.read('payload'))
  #   end
  #
  # An Array is joined into a JSON array without its members being parsed, which is
  # what makes a cached collection cheap — N rendered blobs are spliced together
  # rather than round-tripped:
  #
  #   Grape::PrecompiledJson.new(['{"id":1}', '{"id":2}']).to_s # => '[{"id":1},{"id":2}]'
  #
  # +Array#join+ calls +to_s+ on each member, so members may themselves be
  # +PrecompiledJson+ instances.
  #
  # Wrap only the whole body. A wrapper nested inside a Hash or Array that is then
  # handed to an encoder is serialized as an ordinary object — +ActiveSupport::JSON+
  # renders it through +as_json+ as +{"value":"{\"a\":1}"}+ — because no encoder knows
  # to unwrap it. Nothing checks that the String actually holds JSON; that is the
  # caller's responsibility.
  class PrecompiledJson
    # @param value [String, Array<String>] pre-rendered JSON
    def initialize(value)
      @value = value
    end

    # @return [String] the JSON to serve
    # @raise [Grape::Exceptions::InvalidFormatter] if the value is neither a String
    #   nor an Array; the formatter middleware turns this into a 500 rather than
    #   letting a body Rack cannot serve reach the SPEC check.
    def to_s
      return @value if @value.is_a?(String)
      return "[#{@value.join(',')}]" if @value.is_a?(Array)

      raise Grape::Exceptions::InvalidFormatter.new(@value.class, 'json')
    end
  end
end
