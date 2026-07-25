# frozen_string_literal: true

# Layer-2 thread-safety stress tests: concurrent requests against one shared,
# compiled API, asserting per-request state stays per-request. Unlike the
# Layer-1 invariant specs (frozen graph, boot-only caches) these exercise the
# live request path under real threads — on MRI they catch logic bleed
# (state leaking between requests); on JRuby/TruffleRuby (edge workflow, which
# runs the full suite) they additionally run with true parallelism.
#
# Every thread asserts an exact, thread-specific response, so any
# cross-request contamination produces a deterministic failure message — the
# tests never rely on observing a torn write by luck.
RSpec.describe Grape::API do
  describe 'concurrent requests' do
    # Spawns +threads+ threads, holds them at a gate until all are ready,
    # then releases them together so requests overlap as much as the runtime
    # allows. Returns { thread_index => [iteration results] };
    # Thread#value re-raises anything a thread raised.
    def run_concurrently(threads: 8, iterations: 5)
      ready = Queue.new
      gate = Queue.new
      spawned = Array.new(threads) do |thread_index|
        Thread.new do
          ready << thread_index
          gate.pop
          Array.new(iterations) { |iteration| yield(thread_index, iteration) }
        end
      end
      threads.times { ready.pop }
      threads.times { gate << true }
      spawned.each_with_index.to_h { |thread, thread_index| [thread_index, thread.value] }
    end

    it 'keeps array index tracking isolated between requests' do
      # ParamScopeTracker holds per-request bracket indices in fiber-local
      # storage. Each thread plants the invalid element at its own index; a
      # tracker bleed would surface as another thread's index in the error.
      app = Class.new(described_class) do
        format :json
        params do
          requires :list, type: Array do
            requires :name, type: String
          end
        end
        post('/items') { 'ok' }
      end
      app.compile!

      results = run_concurrently do |thread_index, _iteration|
        payload = Array.new(thread_index + 2) { { name: 'present' } }
        payload[thread_index] = {}
        Rack::MockRequest.new(app).post('/items', input: { list: payload }.to_json, 'CONTENT_TYPE' => 'application/json')
      end

      results.each do |thread_index, responses|
        responses.each do |response|
          expect(response.status).to eq(400)
          expect(JSON.parse(response.body)['error']).to eq("list[#{thread_index}][name] is missing")
        end
      end
    end

    it 'gives each request its own copy of a mutable default' do
      # Isolation comes from two independent layers: DefaultValidator dups the
      # declared default per request, and assigning into the params container
      # (HashWithIndifferentAccess) deep-converts the value again. This pins
      # the end-to-end property — it fails only if both layers regress, e.g.
      # a future params builder storing defaults by reference.
      app = Class.new(described_class) do
        format :json
        params do
          requires :tag, type: String
          optional :opts, type: Hash, default: { tags: [] }
        end
        post('/tags') do
          params[:opts][:tags] << params[:tag]
          { tags: params[:opts][:tags] }
        end
      end
      app.compile!

      results = run_concurrently do |thread_index, iteration|
        tag = "tag-#{thread_index}-#{iteration}"
        [tag, Rack::MockRequest.new(app).post('/tags', input: { tag: }.to_json, 'CONTENT_TYPE' => 'application/json')]
      end

      results.each_value do |responses|
        responses.each do |tag, response|
          expect(response.status).to eq(201)
          expect(JSON.parse(response.body)).to eq('tags' => [tag])
        end
      end
    end

    it 'compiles a cold API correctly under racing first requests' do
      # The very first calls race Instance#compile! (double-checked LOCK) and
      # the first traversal of the shared coercer graph. Repeated with fresh
      # cold apps so the uncompiled window is hit several times.
      4.times do
        app = Class.new(described_class) do
          format :json
          params do
            requires :id, type: Integer
            optional :ids, type: Array[Integer]
            optional :multi, type: [Integer, String]
          end
          get('/first') { { id: params[:id], ids: params[:ids] } }
        end

        results = run_concurrently(iterations: 1) do |thread_index, _iteration|
          Rack::MockRequest.new(app).get("/first?id=#{thread_index}&ids[]=#{thread_index}0&multi[]=x")
        end

        results.each do |thread_index, responses|
          responses.each do |response|
            expect(response.status).to eq(200)
            expect(JSON.parse(response.body)).to eq('id' => thread_index, 'ids' => [thread_index * 10])
          end
        end
      end
    end
  end
end
