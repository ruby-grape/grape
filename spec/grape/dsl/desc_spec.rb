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
      it 'is rejected -- options are keyword arguments' do
        expect { subject.desc 'The description', { message: 'none' } }.to raise_error(ArgumentError)
      end
    end

    context 'when the deprecated default option is passed' do
      it 'is deprecated' do
        expect { subject.desc 'The description', default: { code: 400 } }.to raise_error(ActiveSupport::DeprecationException, /default_response/)
      end

      it 'stores it under default_response when deprecations are silenced' do
        Grape.deprecator.silence { subject.desc 'The description', default: { code: 400 } }
        expect(subject.route_setting(:description)).to include(default_response: { code: 400 })
        expect(subject.route_setting(:description)).not_to have_key(:default)
      end

      # Reviewed on #2861: `desc` must not mutate the Hash it was handed.
      it 'does not modify the caller options Hash' do
        options = { default: { code: 400 } }
        Grape.deprecator.silence { subject.desc 'The description', **options }
        expect(options).to eq(default: { code: 400 })
      end

      it 'does not overwrite an explicit default_response' do
        Grape.deprecator.silence do
          subject.desc 'The description', default: { code: 400 }, default_response: { code: 500 }
        end
        expect(subject.route_setting(:description)).to include(default_response: { code: 500 })
      end
    end

    context 'when the deprecated default is called in a block' do
      it 'is deprecated' do
        expect { subject.desc('The description') { default(code: 400) } }.to raise_error(ActiveSupport::DeprecationException, /default_response/)
      end

      it 'writes the default_response key when deprecations are silenced' do
        Grape.deprecator.silence { subject.desc('The description') { default(code: 400) } }
        expect(subject.route_setting(:description)).to include(default_response: { code: 400 })
        expect(subject.route_setting(:description)).not_to have_key(:default)
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
          default_response: { code: 400, message: 'Invalid' },
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
          default_response code: 400, message: 'Invalid'
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
  end
end
