# frozen_string_literal: true

# Fuzz test for adversarial nesting depth.
#
# Several validation-runtime paths recurse on the *shape* of the incoming
# params rather than on anything Grape controls: AttributesIterator#do_each
# recurses into nested arrays, and coercion/oneof walk nested hashes and
# arrays. A deeply nested payload is therefore a resource-exhaustion surface.
#
# In practice the upstream parsers cap depth long before Grape's own recursion
# ceiling is reached (Rack::Utils.param_depth_limit for query/form bodies,
# JSON's max_nesting for JSON bodies), so an over-the-wire request degrades to
# a controlled 4xx. This spec fuzzes random shapes and depths through every
# recursive path and asserts the invariant that matters: a request is never
# answered with a 5xx / uncaught exception, no matter how it is nested.
#
# +AttributesIterator+ is the primary recursion site under test; the other
# paths (Hash/JSON coercion, oneof) are exercised through the same requests.
describe Grape::Validations::AttributesIterator do
  describe 'adversarial nesting depth', :aggregate_failures do
    subject(:app) do
      Class.new(Grape::API) do
        format :json
        # No rescue_from: Grape's own error middleware turns parse/validation
        # failures into 4xx. Anything Grape does *not* recognise (a genuine
        # crash such as SystemStackError) propagates instead — surfacing as a
        # 5xx status or a raised exception that fails the example. Both are
        # what we hunt.

        params do
          requires :list, type: Array do
            requires :name, type: String
          end
        end
        post('/array_scope') { 'ok' }

        params do
          requires :root, type: Hash do
            requires :name, type: String
          end
        end
        post('/hash_scope') { 'ok' }

        params do
          requires :doc, type: JSON do
            requires :name, type: String
          end
        end
        post('/json_type') { 'ok' }

        params do
          requires :value, type: Hash, oneof: [proc { requires :x, type: Integer }]
        end
        post('/oneof') { 'ok' }

        params do
          requires :ids, type: Set[Integer]
        end
        post('/set_coercion') { 'ok' }
      end
    end

    # Deterministic per RSpec seed: a failing run reproduces with --seed <n>.
    let(:rng) { Random.new(RSpec.configuration.seed) }
    let(:endpoints) { %w[/array_scope /hash_scope /json_type /oneof /set_coercion] }
    let(:shapes) { %i[array hash mixed] }
    let(:leaves) { ['"x"', '1', 'true', '{"name":"x"}', 'null'] }

    # A raw JSON fragment nested +depth+ levels deep in the given shape.
    def nested_fragment(depth, shape, leaf)
      case shape
      when :array then ('[' * depth) + leaf + (']' * depth)
      when :hash  then ('{"k":' * depth) + leaf + ('}' * depth)
      else # :mixed — alternate array and hash wrappers
        frag = leaf
        depth.times { |i| frag = i.even? ? "[#{frag}]" : %({"k":#{frag}}) }
        frag
      end
    end

    # Build a raw request body targeting +endpoint+ with a payload nested
    # +depth+ levels deep. The top-level key each endpoint requires is wrapped
    # around the adversarial fragment.
    def adversarial_body(endpoint, depth, shape, leaf)
      fragment = nested_fragment(depth, shape, leaf)
      case endpoint
      when '/array_scope'  then %({"list":#{fragment}})
      when '/hash_scope'   then %({"root":#{fragment}})
      when '/oneof'        then %({"value":#{fragment}})
      when '/set_coercion' then %({"ids":#{fragment}})
      when '/json_type'    then %({"doc":#{fragment.to_json}}) # coerced via JSON.parse
      end
    end

    it 'never answers a deeply nested request with a 5xx' do
      300.times do
        endpoint = endpoints.sample(random: rng)
        shape = shapes.sample(random: rng)
        leaf = leaves.sample(random: rng)
        # Span both sides of the parser limits: depths <100 actually reach and
        # exercise Grape's recursion; depths >100 are rejected upstream.
        depth = rng.rand(1..400)
        body = adversarial_body(endpoint, depth, shape, leaf)

        post endpoint, body, 'CONTENT_TYPE' => 'application/json'

        expect(last_response.status).to(
          be < 500,
          "5xx on #{endpoint} shape=#{shape} depth=#{depth} leaf=#{leaf}: " \
          "#{last_response.status} #{last_response.body[0, 200]}"
        )
      end
    end

    # Anchored extremes: well past every parser limit and past Grape's own
    # recursion ceiling, on every endpoint and shape, run regardless of RNG.
    anchored_endpoints = %w[/array_scope /hash_scope /json_type /oneof /set_coercion]
    anchored_shapes = %i[array hash mixed]

    [100, 500, 2000].each do |depth|
      context "at depth #{depth}" do
        anchored_endpoints.each do |endpoint|
          anchored_shapes.each do |shape|
            it "degrades gracefully on #{endpoint} (#{shape})" do
              body = adversarial_body(endpoint, depth, shape, '{"name":"x"}')

              post endpoint, body, 'CONTENT_TYPE' => 'application/json'

              expect(last_response.status).to be < 500
            end
          end
        end
      end
    end
  end
end
