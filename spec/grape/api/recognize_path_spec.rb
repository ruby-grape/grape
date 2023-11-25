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

    context 'when parametrized route with type specified together with a static route' do
      subject do
        Class.new(described_class) do
          resource :books do
            route_param :id, type: Integer do
              get do
              end

              resource :loans do
                route_param :loan_id, type: Integer do
                  get do
                  end
                end

                resource :print do
                  post do
                  end
                end
              end
            end

            resource :share do
              post do
              end
            end
          end
        end
      end

      it 'recognizes the static route when the parameter does not match with the specified type' do
        actual = subject.recognize_path('/books/share').routes[0].origin
        expect(actual).to eq('/books/share')
      end

      it 'does not recognize any endpoint when there is not other endpoint that matches with the requested path' do
        actual = subject.recognize_path('/books/other')
        expect(actual).to be_nil
      end

      it 'recognizes the parametrized route when the parameter matches with the specified type' do
        actual = subject.recognize_path('/books/1').routes[0].origin
        expect(actual).to eq('/books/:id')
      end

      it 'recognizes the static nested route when the parameter does not match with the specified type' do
        actual = subject.recognize_path('/books/1/loans/print').routes[0].origin
        expect(actual).to eq('/books/:id/loans/print')
      end

      it 'recognizes the nested parametrized route when the parameter matches with the specified type' do
        actual = subject.recognize_path('/books/1/loans/33').routes[0].origin
        expect(actual).to eq('/books/:id/loans/:loan_id')
      end
    end
  end
end
