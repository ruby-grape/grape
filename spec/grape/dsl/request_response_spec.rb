require 'spec_helper'

module Grape
  module DSL
    module RequestResponseSpec
      class Dummy
        include Grape::DSL::RequestResponse

        def self.settings
          @settings ||= Grape::Util::HashStack.new
        end

        def self.set(key, value)
          settings[key.to_sym] = value
        end

        def self.imbue(key, value)
          settings.imbue(key, value)
        end
      end
    end

    describe RequestResponse do
      subject { Class.new(RequestResponseSpec::Dummy) }
      let(:c_type) { 'application/json' }
      let(:format) { 'txt' }

      describe '.default_format' do
        it 'sets the default format' do
          expect(subject).to receive(:set).with(:default_format, :format)
          subject.default_format :format
        end

        it 'returns the format without paramter' do
          subject.default_format :format

          expect(subject.default_format).to eq :format
        end
      end

      describe '.format' do
        it 'sets a new format' do
          expect(subject).to receive(:set).with(:format, format.to_sym)
          expect(subject).to receive(:set).with(:default_error_formatter, Grape::ErrorFormatter::Txt)

          subject.format format
        end
      end

      describe '.formatter' do
        it 'sets the formatter for a content type' do
          expect(subject.settings).to receive(:imbue).with(:formatters, c_type.to_sym => :formatter)
          subject.formatter c_type, :formatter
        end
      end

      describe '.parser' do
        it 'sets a parser for a content type' do
          expect(subject.settings).to receive(:imbue).with(:parsers, c_type.to_sym => :parser)
          subject.parser c_type, :parser
        end
      end

      describe '.default_error_formatter' do
        it 'sets a new error formatter' do
          expect(subject).to receive(:set).with(:default_error_formatter, Grape::ErrorFormatter::Json)
          subject.default_error_formatter :json
        end
      end

      describe '.error_formatter' do
        it 'sets a error_formatter' do
          format = 'txt'
          expect(subject.settings).to receive(:imbue).with(:error_formatters, format.to_sym => :error_formatter)
          subject.error_formatter format, :error_formatter
        end

        it 'understands syntactic sugar' do
          expect(subject.settings).to receive(:imbue).with(:error_formatters, format.to_sym => :error_formatter)
          subject.error_formatter format, with: :error_formatter
        end
      end

      describe '.content_type' do
        it 'sets a content type for a format' do
          expect(subject.settings).to receive(:imbue).with(:content_types, format.to_sym => c_type)
          subject.content_type format, c_type
        end
      end

      describe '.content_types' do
        it 'returns all content types' do
          expect(subject.content_types).to eq(xml: "application/xml",
                                              serializable_hash: "application/json",
                                              json: "application/json",
                                              txt: "text/plain",
                                              binary: "application/octet-stream")
        end
      end

      describe '.default_error_status' do
        it 'sets a default error status' do
          expect(subject).to receive(:set).with(:default_error_status, 500)
          subject.default_error_status 500
        end
      end

      xdescribe '.rescue_from' do
        it 'does some thing'
      end

      describe '.represent' do
        it 'sets a presenter for a class' do
          presenter = Class.new
          expect(subject).to receive(:imbue).with(:representations, ThisClass: presenter)
          subject.represent :ThisClass, with: presenter
        end
      end
    end
  end
end
