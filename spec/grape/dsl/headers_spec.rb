# frozen_string_literal: true

module Grape
  module DSL
    module HeadersSpec
      class Dummy
        include Grape::DSL::Headers
      end
    end
    describe Headers do
      subject { HeadersSpec::Dummy.new }

      let(:header_data) do
        { 'First Key' => 'First Value',
          'Second Key' => 'Second Value' }
      end

      context 'when headers are set' do
        describe '#header' do
          before do
            header_data.each { |k, v| subject.header(k, v) }
          end

          describe 'get' do
            it 'returns a specifc value' do
              expect(subject.header['First Key']).to eq 'First Value'
              expect(subject.header['Second Key']).to eq 'Second Value'
            end

            it 'returns all set headers' do
              expect(subject.header).to eq header_data
              expect(subject.headers).to eq header_data
            end
          end

          describe 'set' do
            it 'returns value' do
              expect(subject.header('Third Key', 'Third Value'))
              expect(subject.header['Third Key']).to eq 'Third Value'
            end
          end

          describe 'delete' do
            it 'deletes a header key-value pair' do
              expect(subject.header('First Key')).to eq header_data['First Key']
              expect(subject.header).not_to have_key('First Key')
            end
          end
        end
      end

      context 'when no headers are set' do
        describe '#header' do
          it 'returns nil' do
            expect(subject.header['First Key']).to be_nil
            expect(subject.header('First Key')).to be_nil
          end
        end
      end
    end
  end
end
