# frozen_string_literal: true

require 'open3'

describe Grape::Util::Shareable do
  # What this module settles -- Grape's configuration, Rack's lookup tables, a
  # snapshot of the translations -- is process-wide and frozen afterwards,
  # while the rest of the suite goes on writing to all three. So every example
  # that gets as far as finalize! runs in a process of its own.
  def run(source)
    Open3.capture3(RbConfig.ruby, '-W0', '-Ilib', '-e', source)
  end

  # The script's own stderr is the only account of what went wrong inside it,
  # so a failure carries it rather than leaving an empty stdout to compare.
  def output_of(source)
    stdout, stderr, status = run(source)
    raise "the script exited #{status.exitstatus}:\n#{stderr}" unless status.success?

    stdout
  end

  let(:api_source) do
    <<~RUBY
      require 'grape'
      Grape.ractor!

      class RactorAPI < Grape::API
        format :json
        params { requires :name, type: String }
        get('/hello') { { hello: params[:name] } }

        # A Symbol status is why Rack::Utils has to be settled too: nothing
        # reads SYMBOL_TO_STATUS_CODE until an endpoint answers one.
        get('/created') do
          status :created
          { ok: true }
        end
      end

      RactorAPI.finalize!

      def env_for(query)
        { 'REQUEST_METHOD' => 'GET', 'PATH_INFO' => '/hello', 'QUERY_STRING' => query,
          'SERVER_NAME' => 'example.org', 'SERVER_PORT' => '80', 'HTTP_HOST' => 'example.org',
          'rack.url_scheme' => 'http', 'rack.input' => StringIO.new, 'SCRIPT_NAME' => '' }
      end

      def answer_to(query)
        RactorAPI.call(env_for(query)).then { |status, _headers, body| [status, body.to_a.join] }
      end
    RUBY
  end

  describe '.supported?' do
    it 'refuses to turn the mode on when this Ruby cannot support it' do
      skip 'this Ruby can make a Method shareable' if described_class.supported?

      expect { Grape.ractor! }.to raise_error(Grape::Exceptions::RactorModeUnsupported, /4\.0 and later/)
    end
  end

  # Ruby 3.3 and 3.4 cannot make a Method shareable, and Grape.ractor! says so
  # rather than leaving an API half-frozen, so the mode is moot there.
  context 'when this Ruby can make a Method shareable' do
    before { skip "#{RUBY_VERSION} cannot make a Method shareable" unless described_class.supported? }

    describe 'finalize!' do
      it 'refuses to finalize before Ractor mode is on' do
        expect { Class.new(Grape::API).finalize! }.to raise_error(Grape::Exceptions::RactorModeNotEnabled, /Grape.ractor!/)
      end

      it 'answers the API class it was called on' do
        stdout = output_of("#{api_source}\nputs RactorAPI.finalize!.equal?(RactorAPI)")
        expect(stdout).to eq("true\n")
      end

      it 'makes the compiled API shareable' do
        stdout = output_of("#{api_source}\nputs Ractor.shareable?(RactorAPI.base_instance.compile!)")
        expect(stdout).to eq("true\n")
      end

      it 'leaves the configuration readable from a Ractor, and frozen' do
        stdout = output_of("#{api_source}\nputs (Ractor.new { Grape.config[:param_builder] }.value)\nputs Grape.config.frozen?")
        expect(stdout).to eq("hash_with_indifferent_access\ntrue\n")
      end
    end

    describe 'serving from a non-main Ractor' do
      it 'answers a request' do
        stdout = output_of("#{api_source}\nputs (Ractor.new { answer_to('name=ada').inspect }.value)")
        expect(stdout).to eq("[200, \"{\\\"hello\\\":\\\"ada\\\"}\"]\n")
      end

      it 'answers a status named by a Symbol' do
        stdout = output_of("#{api_source}\nputs Ractor.new { RactorAPI.call(env_for('').merge('PATH_INFO' => '/created')).first }.value")
        expect(stdout).to eq("201\n")
      end

      it 'answers a validation error with the message the translations carry' do
        stdout = output_of("#{api_source}\nputs (Ractor.new { answer_to('').inspect }.value)")
        expect(stdout).to eq("[400, \"{\\\"error\\\":\\\"name is missing\\\"}\"]\n")
      end

      it 'answers what the main Ractor answers' do
        stdout = output_of("#{api_source}\nputs answer_to('name=ada') == (Ractor.new { answer_to('name=ada') }.value)")
        expect(stdout).to eq("true\n")
      end

      it 'answers the same from several Ractors at once' do
        source = "#{api_source}\n" \
                 "answers = 4.times.map { Ractor.new { 25.times.map { answer_to('name=ada') }.uniq } }.map(&:value)\n" \
                 'puts answers.flatten(1).uniq.inspect'
        stdout = output_of(source)
        expect(stdout).to eq("[[200, \"{\\\"hello\\\":\\\"ada\\\"}\"]]\n")
      end
    end

    describe 'a route block that cannot be isolated' do
      it 'says so as the API class loads, naming the variable it captured' do
        source = <<~RUBY
          require 'grape'
          Grape.ractor!
          captured = { mutable: true }
          Class.new(Grape::API) { get('/x') { captured } }
        RUBY
        _, stderr, status = run(source)
        expect(status).not_to be_success
        # Ruby 3.3 quotes the variable as `captured', 4.0 as 'captured'.
        expect(stderr).to include('Ractor::IsolationError').and match(/variable .captured./)
      end
    end
  end
end
