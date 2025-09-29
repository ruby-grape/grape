# frozen_string_literal: true

describe Grape::DSL::RequestResponse do
  subject { dummy_class }

  let(:dummy_class) do
    Class.new do
      extend Grape::DSL::RequestResponse
      extend Grape::DSL::Settings
    end
  end

  let(:c_type) { 'application/json' }
  let(:format) { 'txt' }

  describe '.default_format' do
    it 'sets the default format' do
      subject.default_format :format
      expect(subject.inheritable_setting.namespace_inheritable[:default_format]).to eq(:format)
    end

    it 'returns the format without paramter' do
      subject.default_format :format
      expect(subject.default_format).to eq :format
    end
  end

  describe '.format' do
    it 'sets a new format' do
      subject.format format
      expect(subject.inheritable_setting.namespace_inheritable[:format]).to eq(format.to_sym)
      expect(subject.inheritable_setting.namespace_inheritable[:default_error_formatter]).to eq(Grape::ErrorFormatter::Txt)
    end
  end

  describe '.formatter' do
    it 'sets the formatter for a content type' do
      subject.formatter c_type, :formatter
      expect(subject.inheritable_setting.namespace_stackable[:formatters]).to eq([c_type.to_sym => :formatter])
    end
  end

  describe '.parser' do
    it 'sets a parser for a content type' do
      subject.parser c_type, :parser
      expect(subject.inheritable_setting.namespace_stackable[:parsers]).to eq([c_type.to_sym => :parser])
    end
  end

  describe '.default_error_formatter' do
    it 'sets a new error formatter' do
      subject.default_error_formatter :json
      expect(subject.inheritable_setting.namespace_inheritable[:default_error_formatter]).to eq(Grape::ErrorFormatter::Json)
    end
  end

  describe '.error_formatter' do
    it 'sets a error_formatter' do
      format = 'txt'
      subject.error_formatter format, :error_formatter
      expect(subject.inheritable_setting.namespace_stackable[:error_formatters]).to eq([{ format.to_sym => :error_formatter }])
    end

    it 'understands syntactic sugar' do
      subject.error_formatter format, with: :error_formatter
      expect(subject.inheritable_setting.namespace_stackable[:error_formatters]).to eq([{ format.to_sym => :error_formatter }])
    end
  end

  describe '.content_type' do
    it 'sets a content type for a format' do
      subject.content_type format, c_type
      expect(subject.inheritable_setting.namespace_stackable[:content_types]).to eq([format.to_sym => c_type])
    end
  end

  describe '.content_types' do
    it 'returns all content types' do
      expect(subject.content_types).to eq(xml: 'application/xml',
                                          serializable_hash: 'application/json',
                                          json: 'application/json',
                                          txt: 'text/plain',
                                          binary: 'application/octet-stream')
    end
  end

  describe '.default_error_status' do
    it 'sets a default error status' do
      subject.default_error_status 500
      expect(subject.inheritable_setting.namespace_inheritable[:default_error_status]).to eq(500)
    end
  end

  describe '.rescue_from' do
    describe ':all' do
      it 'sets rescue all to true' do
        subject.rescue_from :all
        expect(subject.inheritable_setting.namespace_inheritable.to_hash).to eq(
          {
            rescue_all: true,
            all_rescue_handler: nil
          }
        )
      end

      it 'sets given proc as rescue handler' do
        rescue_handler_proc = proc {}
        subject.rescue_from :all, rescue_handler_proc
        expect(subject.inheritable_setting.namespace_inheritable.to_hash).to eq(
          {
            rescue_all: true,
            all_rescue_handler: rescue_handler_proc
          }
        )
      end

      it 'sets given block as rescue handler' do
        rescue_handler_proc = proc {}
        subject.rescue_from :all, &rescue_handler_proc
        expect(subject.inheritable_setting.namespace_inheritable.to_hash).to eq(
          {
            rescue_all: true,
            all_rescue_handler: rescue_handler_proc
          }
        )
      end

      it 'sets a rescue handler declared through :with option' do
        with_block = -> { 'hello' }
        subject.rescue_from :all, with: with_block
        expect(subject.inheritable_setting.namespace_inheritable.to_hash).to eq(
          {
            rescue_all: true,
            all_rescue_handler: with_block
          }
        )
      end

      it 'abort if :with option value is not Symbol, String or Proc' do
        expect { subject.rescue_from :all, with: 1234 }.to raise_error(ArgumentError, "with: #{integer_class_name}, expected Symbol, String or Proc")
      end

      it 'abort if both :with option and block are passed' do
        expect do
          subject.rescue_from :all, with: -> { 'hello' } do
            error!('bye')
          end
        end.to raise_error(ArgumentError, 'both :with option and block cannot be passed')
      end
    end

    describe ':grape_exceptions' do
      it 'sets rescue all to true' do
        subject.rescue_from :grape_exceptions
        expect(subject.inheritable_setting.namespace_inheritable.to_hash).to eq(
          {
            rescue_all: true,
            rescue_grape_exceptions: true,
            grape_exceptions_rescue_handler: nil
          }
        )
      end

      it 'sets given proc as rescue handler' do
        rescue_handler_proc = proc {}
        subject.rescue_from :grape_exceptions, rescue_handler_proc
        expect(subject.inheritable_setting.namespace_inheritable.to_hash).to eq(
          {
            rescue_all: true,
            rescue_grape_exceptions: true,
            grape_exceptions_rescue_handler: rescue_handler_proc
          }
        )
      end

      it 'sets given block as rescue handler' do
        rescue_handler_proc = proc {}
        subject.rescue_from :grape_exceptions, &rescue_handler_proc
        expect(subject.inheritable_setting.namespace_inheritable.to_hash).to eq(
          {
            rescue_all: true,
            rescue_grape_exceptions: true,
            grape_exceptions_rescue_handler: rescue_handler_proc
          }
        )
      end

      it 'sets a rescue handler declared through :with option' do
        with_block = -> { 'hello' }
        subject.rescue_from :grape_exceptions, with: with_block
        expect(subject.inheritable_setting.namespace_inheritable.to_hash).to eq(
          {
            rescue_all: true,
            rescue_grape_exceptions: true,
            grape_exceptions_rescue_handler: with_block
          }
        )
      end
    end

    describe 'list of exceptions is passed' do
      it 'sets hash of exceptions as rescue handlers' do
        subject.rescue_from StandardError
        expect(subject.inheritable_setting.namespace_reverse_stackable[:rescue_handlers]).to eq([StandardError => nil])
        expect(subject.inheritable_setting.namespace_stackable[:rescue_options]).to eq([{}])
      end

      it 'rescues only base handlers if rescue_subclasses: false option is passed' do
        subject.rescue_from StandardError, rescue_subclasses: false
        expect(subject.inheritable_setting.namespace_reverse_stackable[:base_only_rescue_handlers]).to eq([StandardError => nil])
        expect(subject.inheritable_setting.namespace_stackable[:rescue_options]).to eq([rescue_subclasses: false])
      end

      it 'sets given proc as rescue handler for each key in hash' do
        rescue_handler_proc = proc {}
        subject.rescue_from StandardError, rescue_handler_proc
        expect(subject.inheritable_setting.namespace_reverse_stackable[:rescue_handlers]).to eq([StandardError => rescue_handler_proc])
        expect(subject.inheritable_setting.namespace_stackable[:rescue_options]).to eq([{}])
      end

      it 'sets given block as rescue handler for each key in hash' do
        rescue_handler_proc = proc {}
        subject.rescue_from StandardError, &rescue_handler_proc
        expect(subject.inheritable_setting.namespace_reverse_stackable[:rescue_handlers]).to eq([StandardError => rescue_handler_proc])
        expect(subject.inheritable_setting.namespace_stackable[:rescue_options]).to eq([{}])
      end

      it 'sets a rescue handler declared through :with option for each key in hash' do
        with_block = -> { 'hello' }
        subject.rescue_from StandardError, with: with_block
        expect(subject.inheritable_setting.namespace_reverse_stackable[:rescue_handlers]).to eq([StandardError => with_block])
        expect(subject.inheritable_setting.namespace_stackable[:rescue_options]).to eq([{}])
      end
    end
  end

  describe '.represent' do
    it 'sets a presenter for a class' do
      presenter = Class.new
      subject.represent :ThisClass, with: presenter
      expect(subject.inheritable_setting.namespace_stackable[:representations]).to eq([ThisClass: presenter])
    end
  end
end
