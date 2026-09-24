# frozen_string_literal: true

module Acme
  module Entities
    class Tool < Grape::Entity
      root 'tools', 'tool'
      expose :id
      expose :length, documentation: { type: :string, desc: 'length of the tool' }
      expose :weight, documentation: { type: :string, desc: 'weight of the tool' }
      expose :foo, documentation: { type: :string, desc: 'foo' }, if: ->(_tool, options) { options[:foo] } do |_tool, options|
        options[:foo]
      end
    end

    class API < Grape::API
      format :json
      content_type :xml, 'application/xml'
      formatter :xml, proc { |object|
        object[object.keys.first].to_xml root: object.keys.first
      }
      desc 'Exposes an entity'
      namespace :entities do
        desc  'Expose a tool',
              params: Acme::Entities::Tool.documentation,
              success: Acme::Entities::Tool
        get ':id' do
          present OpenStruct.new(id: params[:id], length: 10, weight: '20kg'), with: Acme::Entities::Tool, foo: params[:foo]
        end
      end
    end
  end
end
