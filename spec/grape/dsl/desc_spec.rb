# frozen_string_literal: true

describe Grape::DSL::Desc do
  subject { dummy_class }

  let(:dummy_class) do
    Class.new do
      extend Grape::DSL::Desc
      extend Grape::DSL::Settings
    end
  end

  describe '.desc' do
    it 'sets a description' do
      desc_text = 'The description'
      options = { message: 'none' }
      subject.desc desc_text, **options
      expect(subject.route_setting(:description)).to eq(options.merge(description: desc_text))
      expect(subject.namespace_setting(:description)).to be_nil
    end

    context 'when a positional options Hash is passed' do
      let(:desc_text) { 'The description' }
      let(:options) { { message: 'none' } }

      it 'is deprecated' do
        expect { subject.desc desc_text, options }.to raise_error(ActiveSupport::DeprecationException)
      end

      it 'still sets the description when deprecations are silenced' do
        Grape.deprecator.silence do
          subject.desc desc_text, options
        end
        expect(subject.route_setting(:description)).to eq(options.merge(description: desc_text))
        expect(subject.namespace_setting(:description)).to be_nil
      end
    end

    context 'when a block is passed' do
      let(:expected_options) do
        {
          summary: 'summary',
          description: 'The description',
          detail: 'more details',
          params: { first: :param },
          entity: Object,
          default: { code: 400, message: 'Invalid' },
          http_codes: [[401, 'Unauthorized', 'Entities::Error']],
          named: 'My named route',
          body_name: 'My body name',
          headers: [
            {
              XAuthToken: {
                description: 'Valdates your identity',
                required: true
              },
              XOptionalHeader: {
                description: 'Not really needed',
                required: false
              }
            }
          ],
          hidden: false,
          deprecated: false,
          is_array: true,
          nickname: 'nickname',
          produces: %w[array of mime_types],
          consumes: %w[array of mime_types],
          tags: %w[tag1 tag2],
          security: %w[array of security schemes]
        }
      end

      it 'can be set with a block' do
        subject.desc 'The description' do
          summary 'summary'
          detail 'more details'
          params(first: :param)
          success Object
          default code: 400, message: 'Invalid'
          failure [[401, 'Unauthorized', 'Entities::Error']]
          named 'My named route'
          body_name 'My body name'
          headers [
            {
              XAuthToken: {
                description: 'Valdates your identity',
                required: true
              },
              XOptionalHeader: {
                description: 'Not really needed',
                required: false
              }
            }
          ]
          hidden false
          deprecated false
          is_array true
          nickname 'nickname'
          produces %w[array of mime_types]
          consumes %w[array of mime_types]
          tags %w[tag1 tag2]
          security %w[array of security schemes]
        end

        expect(subject.route_setting(:description)).to eq(expected_options)
        expect(subject.namespace_setting(:description)).to be_nil
      end
    end

    # `success` and `failure` are the block form's aliases for `entity` and
    # `http_codes`. A Hash never reaches Grape::Util::ApiDescription, so the
    # aliases are normalized on the way in and both forms store alike.
    describe 'the success and failure aliases' do
      it 'stores a Hash success under entity and failure under http_codes' do
        subject.desc 'The description', success: Object, failure: [[401, 'Unauthorized']]

        expect(subject.route_setting(:description)).to eq(
          description: 'The description', entity: Object, http_codes: [[401, 'Unauthorized']]
        )
      end

      it 'lets an explicit entity or http_codes win over its alias' do
        subject.desc 'The description', entity: Integer, success: Object

        expect(subject.route_setting(:description)).to eq(description: 'The description', entity: Integer)
      end

      it 'leaves a description carrying neither alias untouched' do
        subject.desc 'The description', summary: 'summary'

        expect(subject.route_setting(:description)).to eq(description: 'The description', summary: 'summary')
      end
    end
  end
end
