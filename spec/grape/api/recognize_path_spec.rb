# frozen_string_literal: true

describe Grape::API do
  describe '.recognize_path' do
    subject { Class.new(described_class) }

    it 'fetches endpoint by given path' do
      subject.get('/foo/:id') {}
      subject.get('/bar/:id') {}
      subject.get('/baz/:id') {}

      actual = subject.recognize_path('/bar/1234').routes[0].origin
      expect(actual).to eq('/bar/:id')
    end

    it 'returns nil if given path does not match with registered routes' do
      subject.get {}
      expect(subject.recognize_path('/bar/1234')).to be_nil
    end

    context 'given parametrized route and static route' do
      subject do
        Class.new(described_class) do
          resource :books do
            route_param :id, type: Integer do
              # GET /books/:id
              get do
                'book by id'
              end
            end

            resource :share do
              # POST /books/share
              post do
                'books share'
              end
            end
          end
        end
      end

      it 'recognizes it as static' do
        actual = subject.recognize_path('/books/share').routes[0].origin
        expect(actual).to eq('/books/share')
      end
    end
  end
end
