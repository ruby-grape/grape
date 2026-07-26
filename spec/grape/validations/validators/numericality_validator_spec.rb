# frozen_string_literal: true

describe Grape::Validations::Validators::NumericalityValidator do
  describe '/greater_than' do
    let(:app) do
      Class.new(Grape::API) do
        params do
          requires :quantity, type: Integer, numericality: { greater_than: 0 }
        end
        post 'greater_than' do
        end
      end
    end

    context 'when value is greater than the limit' do
      it do
        post '/greater_than', quantity: 1
        expect(last_response.status).to eq(201)
        expect(last_response.body).to eq('')
      end
    end

    context 'when value is equal to the limit' do
      it do
        post '/greater_than', quantity: 0
        expect(last_response.status).to eq(400)
        expect(last_response.body).to eq('quantity must be greater than 0')
      end
    end

    context 'when value is less than the limit' do
      it do
        post '/greater_than', quantity: -1
        expect(last_response.status).to eq(400)
        expect(last_response.body).to eq('quantity must be greater than 0')
      end
    end
  end

  describe '/greater_than_or_equal_to' do
    let(:app) do
      Class.new(Grape::API) do
        params do
          requires :quantity, type: Integer, numericality: { greater_than_or_equal_to: 0 }
        end
        post 'greater_than_or_equal_to' do
        end
      end
    end

    context 'when value is equal to the limit' do
      it do
        post '/greater_than_or_equal_to', quantity: 0
        expect(last_response.status).to eq(201)
        expect(last_response.body).to eq('')
      end
    end

    context 'when value is less than the limit' do
      it do
        post '/greater_than_or_equal_to', quantity: -1
        expect(last_response.status).to eq(400)
        expect(last_response.body).to eq('quantity must be greater than or equal to 0')
      end
    end
  end

  describe '/less_than' do
    let(:app) do
      Class.new(Grape::API) do
        params do
          requires :quantity, type: Integer, numericality: { less_than: 10 }
        end
        post 'less_than' do
        end
      end
    end

    context 'when value is less than the limit' do
      it do
        post '/less_than', quantity: 9
        expect(last_response.status).to eq(201)
        expect(last_response.body).to eq('')
      end
    end

    context 'when value is equal to the limit' do
      it do
        post '/less_than', quantity: 10
        expect(last_response.status).to eq(400)
        expect(last_response.body).to eq('quantity must be less than 10')
      end
    end
  end

  describe '/less_than_or_equal_to' do
    let(:app) do
      Class.new(Grape::API) do
        params do
          requires :quantity, type: Integer, numericality: { less_than_or_equal_to: 10 }
        end
        post 'less_than_or_equal_to' do
        end
      end
    end

    context 'when value is equal to the limit' do
      it do
        post '/less_than_or_equal_to', quantity: 10
        expect(last_response.status).to eq(201)
        expect(last_response.body).to eq('')
      end
    end

    context 'when value is greater than the limit' do
      it do
        post '/less_than_or_equal_to', quantity: 11
        expect(last_response.status).to eq(400)
        expect(last_response.body).to eq('quantity must be less than or equal to 10')
      end
    end
  end

  describe '/equal_to' do
    let(:app) do
      Class.new(Grape::API) do
        params do
          requires :rating, type: Integer, numericality: { equal_to: 5 }
        end
        post 'equal_to' do
        end
      end
    end

    context 'when value matches' do
      it do
        post '/equal_to', rating: 5
        expect(last_response.status).to eq(201)
        expect(last_response.body).to eq('')
      end
    end

    context 'when value does not match' do
      it do
        post '/equal_to', rating: 4
        expect(last_response.status).to eq(400)
        expect(last_response.body).to eq('rating must be equal to 5')
      end
    end
  end

  describe '/other_than' do
    let(:app) do
      Class.new(Grape::API) do
        params do
          requires :code, type: Integer, numericality: { other_than: 0 }
        end
        post 'other_than' do
        end
      end
    end

    context 'when value differs' do
      it do
        post '/other_than', code: 1
        expect(last_response.status).to eq(201)
        expect(last_response.body).to eq('')
      end
    end

    context 'when value matches the excluded value' do
      it do
        post '/other_than', code: 0
        expect(last_response.status).to eq(400)
        expect(last_response.body).to eq('code must be other than 0')
      end
    end
  end

  describe '/range' do
    let(:app) do
      Class.new(Grape::API) do
        params do
          requires :discount, type: Float, numericality: { greater_than_or_equal_to: 0, less_than_or_equal_to: 100 }
        end
        post 'range' do
        end
      end
    end

    context 'when value is within range' do
      it do
        post '/range', discount: 50.0
        expect(last_response.status).to eq(201)
        expect(last_response.body).to eq('')
      end
    end

    context 'when value is below range' do
      it do
        post '/range', discount: -1.0
        expect(last_response.status).to eq(400)
        expect(last_response.body).to eq('discount must be greater than or equal to 0')
      end
    end

    context 'when value is above range' do
      it do
        post '/range', discount: 101.0
        expect(last_response.status).to eq(400)
        expect(last_response.body).to eq('discount must be less than or equal to 100')
      end
    end
  end

  describe '/only_integer' do
    let(:app) do
      Class.new(Grape::API) do
        params do
          requires :amount, type: Float, numericality: { only_integer: true }
        end
        post 'only_integer' do
        end
      end
    end

    context 'when value is a whole number' do
      it do
        post '/only_integer', amount: 5.0
        expect(last_response.status).to eq(201)
        expect(last_response.body).to eq('')
      end
    end

    context 'when value has a fractional part' do
      it do
        post '/only_integer', amount: 5.5
        expect(last_response.status).to eq(400)
        expect(last_response.body).to eq('amount must be an integer')
      end
    end
  end

  describe '/odd' do
    let(:app) do
      Class.new(Grape::API) do
        params do
          requires :number, type: Integer, numericality: { odd: true }
        end
        post 'odd' do
        end
      end
    end

    context 'when value is odd' do
      it do
        post '/odd', number: 3
        expect(last_response.status).to eq(201)
        expect(last_response.body).to eq('')
      end
    end

    context 'when value is even' do
      it do
        post '/odd', number: 4
        expect(last_response.status).to eq(400)
        expect(last_response.body).to eq('number must be odd')
      end
    end
  end

  describe '/even' do
    let(:app) do
      Class.new(Grape::API) do
        params do
          requires :number, type: Integer, numericality: { even: true }
        end
        post 'even' do
        end
      end
    end

    context 'when value is even' do
      it do
        post '/even', number: 4
        expect(last_response.status).to eq(201)
        expect(last_response.body).to eq('')
      end
    end

    context 'when value is odd' do
      it do
        post '/even', number: 3
        expect(last_response.status).to eq(400)
        expect(last_response.body).to eq('number must be even')
      end
    end
  end

  describe '/array_elements' do
    let(:app) do
      Class.new(Grape::API) do
        params do
          requires :numbers, type: [Integer], numericality: { greater_than: 0 }
        end
        post 'array_elements' do
        end
      end
    end

    context 'when every element satisfies the constraint' do
      it do
        post '/array_elements', numbers: [1, 2, 3]
        expect(last_response.status).to eq(201)
        expect(last_response.body).to eq('')
      end
    end

    context 'when one element violates the constraint' do
      it do
        post '/array_elements', numbers: [1, 0, 3]
        expect(last_response.status).to eq(400)
        expect(last_response.body).to eq('numbers must be greater than 0')
      end
    end
  end

  describe '/non_numeric_value' do
    let(:app) do
      Class.new(Grape::API) do
        params do
          requires :code, numericality: { greater_than: 0 }
        end
        post 'non_numeric_value' do
        end
      end
    end

    context 'does not raise an error' do
      it do
        post '/non_numeric_value', code: 'abc'
        expect(last_response.status).to eq(201)
        expect(last_response.body).to eq('')
      end
    end
  end

  describe '/custom-message' do
    let(:app) do
      Class.new(Grape::API) do
        params do
          requires :rating, type: Integer, numericality: { equal_to: 5, message: 'must be a perfect score' }
        end
        post '/custom-message' do
        end
      end
    end

    context 'is valid' do
      it do
        post '/custom-message', rating: 5
        expect(last_response.status).to eq(201)
        expect(last_response.body).to eq('')
      end
    end

    context 'is invalid' do
      it do
        post '/custom-message', rating: 4
        expect(last_response.status).to eq(400)
        expect(last_response.body).to eq('rating must be a perfect score')
      end
    end
  end

  describe '/allow_blank' do
    let(:app) do
      Class.new(Grape::API) do
        params do
          optional :quantity, type: Integer, numericality: { greater_than: 0 }, allow_blank: false
        end
        post 'allow_blank' do
        end
      end
    end

    context 'when not provided' do
      it do
        post '/allow_blank'
        expect(last_response.status).to eq(201)
        expect(last_response.body).to eq('')
      end
    end
  end

  describe '/non_numeric_bound' do
    context 'when a comparison option is not Numeric' do
      let(:app) do
        Class.new(Grape::API) do
          params do
            requires :quantity, type: Integer, numericality: { greater_than: '0' }
          end
          post 'non_numeric_bound' do
          end
        end
      end

      it do
        expect { post 'non_numeric_bound', quantity: 1 }.to raise_error(ArgumentError, 'greater_than must be a Numeric value')
      end
    end
  end

  describe '/greater_than_with_greater_than_or_equal_to' do
    context 'when both options are combined' do
      let(:app) do
        Class.new(Grape::API) do
          params do
            requires :quantity, type: Integer, numericality: { greater_than: 0, greater_than_or_equal_to: 1 }
          end
          post 'greater_than_with_greater_than_or_equal_to' do
          end
        end
      end

      it do
        expect { post 'greater_than_with_greater_than_or_equal_to', quantity: 1 }
          .to raise_error(ArgumentError, 'greater_than cannot be combined with greater_than_or_equal_to')
      end
    end
  end

  describe '/less_than_with_less_than_or_equal_to' do
    context 'when both options are combined' do
      let(:app) do
        Class.new(Grape::API) do
          params do
            requires :quantity, type: Integer, numericality: { less_than: 10, less_than_or_equal_to: 9 }
          end
          post 'less_than_with_less_than_or_equal_to' do
          end
        end
      end

      it do
        expect { post 'less_than_with_less_than_or_equal_to', quantity: 1 }
          .to raise_error(ArgumentError, 'less_than cannot be combined with less_than_or_equal_to')
      end
    end
  end

  describe '/odd_with_even' do
    context 'when both options are combined' do
      let(:app) do
        Class.new(Grape::API) do
          params do
            requires :quantity, type: Integer, numericality: { odd: true, even: true }
          end
          post 'odd_with_even' do
          end
        end
      end

      it do
        expect { post 'odd_with_even', quantity: 1 }.to raise_error(ArgumentError, 'odd cannot be combined with even')
      end
    end
  end

  describe '/equal_to_with_greater_than' do
    context 'when combined with another comparison option' do
      let(:app) do
        Class.new(Grape::API) do
          params do
            requires :quantity, type: Integer, numericality: { equal_to: 5, greater_than: 0 }
          end
          post 'equal_to_with_greater_than' do
          end
        end
      end

      it do
        expect { post 'equal_to_with_greater_than', quantity: 5 }
          .to raise_error(ArgumentError, 'equal_to cannot be combined with other comparison options')
      end
    end
  end

  describe '/reversed_range' do
    context 'when the lower bound is greater than the upper bound' do
      let(:app) do
        Class.new(Grape::API) do
          params do
            requires :quantity, type: Integer, numericality: { greater_than: 10, less_than: 5 }
          end
          post 'reversed_range' do
          end
        end
      end

      it do
        expect { post 'reversed_range', quantity: 1 }.to raise_error(ArgumentError, '10 cannot be greater than 5')
      end
    end
  end
end
