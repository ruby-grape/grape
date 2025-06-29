# frozen_string_literal: true

describe Grape::DSL::Desc do
  subject { dummy_class }

  let(:dummy_class) do
    Class.new do
      extend Grape::DSL::Desc

      def self.namespace_setting(key, value = nil)
        if value
          namespace_setting_hash[key] = value
        else
          namespace_setting_hash[key]
        end
      end

      def self.route_setting(key, value = nil)
        if value
          route_setting_hash[key] = value
        else
          route_setting_hash[key]
        end
      end

      def self.namespace_setting_hash
        @namespace_setting_hash ||= {}
      end

      def self.route_setting_hash
        @route_setting_hash ||= {}
      end
    end
  end

  describe '.desc' do
    it 'sets a description' do
      desc_text = 'The description'
      options = { message: 'none' }
      subject.desc desc_text, options
      expect(subject.namespace_setting(:description)).to eq(options.merge(description: desc_text))
      expect(subject.route_setting(:description)).to eq(options.merge(description: desc_text))
    end

    it 'can be set with a block' do
      expected_options = {
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
          XAuthToken: {
            description: 'Valdates your identity',
            required: true
          },
          XOptionalHeader: {
            description: 'Not really needed',
            required: false
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
          XAuthToken: {
            description: 'Valdates your identity',
            required: true
          },
          XOptionalHeader: {
            description: 'Not really needed',
            required: false
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

      expect(subject.namespace_setting(:description)).to eq(expected_options)
      expect(subject.route_setting(:description)).to eq(expected_options)
    end
  end
end
