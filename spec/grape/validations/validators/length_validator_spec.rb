# frozen_string_literal: true

describe Grape::Validations::Validators::LengthValidator do
  describe '/with_min_max' do
    let(:app) do
      Class.new(Grape::API) do
        params do
          requires :list, length: { min: 2, max: 3 }
        end
        post 'with_min_max' do
        end
      end
    end

    context 'when length is within limits' do
      it do
        post '/with_min_max', list: [1, 2]
        expect(last_response.status).to eq(201)
        expect(last_response.body).to eq('')
      end
    end

    context 'when length is exceeded' do
      it do
        post '/with_min_max', list: [1, 2, 3, 4, 5]
        expect(last_response.status).to eq(400)
        expect(last_response.body).to eq('list is expected to have length within 2 and 3')
      end
    end

    context 'when length is less than minimum' do
      it do
        post '/with_min_max', list: [1]
        expect(last_response.status).to eq(400)
        expect(last_response.body).to eq('list is expected to have length within 2 and 3')
      end
    end
  end

  describe '/with_max_only' do
    let(:app) do
      Class.new(Grape::API) do
        params do
          requires :list, type: [Integer], length: { max: 3 }
        end
        post 'with_max_only' do
        end
      end
    end

    context 'when length is less than limits' do
      it do
        post '/with_max_only', list: [1, 2]
        expect(last_response.status).to eq(201)
        expect(last_response.body).to eq('')
      end
    end

    context 'when length is exceeded' do
      it do
        post '/with_max_only', list: [1, 2, 3, 4, 5]
        expect(last_response.status).to eq(400)
        expect(last_response.body).to eq('list is expected to have length less than or equal to 3')
      end
    end
  end

  describe '/with_min_only' do
    let(:app) do
      Class.new(Grape::API) do
        params do
          requires :list, type: [Integer], length: { min: 2 }
        end
        post 'with_min_only' do
        end
      end
    end

    context 'when length is greater than limit' do
      it do
        post '/with_min_only', list: [1, 2]
        expect(last_response.status).to eq(201)
        expect(last_response.body).to eq('')
      end
    end

    context 'when length is less than limit' do
      it do
        post '/with_min_only', list: [1]
        expect(last_response.status).to eq(400)
        expect(last_response.body).to eq('list is expected to have length greater than or equal to 2')
      end
    end
  end

  describe '/zero_min' do
    let(:app) do
      Class.new(Grape::API) do
        params do
          requires :list, type: [JSON], length: { min: 0 }
        end
        post 'zero_min' do
        end
      end
    end

    context 'when length is equal to the limit' do
      it do
        post '/zero_min', list: '[]'
        expect(last_response.status).to eq(201)
        expect(last_response.body).to eq('')
      end
    end

    context 'when length is greater than limit' do
      it do
        post '/zero_min', list: [{ key: 'value' }]
        expect(last_response.status).to eq(201)
        expect(last_response.body).to eq('')
      end
    end
  end

  describe '/zero_max' do
    let(:app) do
      Class.new(Grape::API) do
        params do
          requires :list, type: [JSON], length: { max: 0 }
        end
        post 'zero_max' do
        end
      end
    end

    context 'when length is within the limit' do
      it do
        post '/zero_max', list: '[]'
        expect(last_response.status).to eq(201)
        expect(last_response.body).to eq('')
      end
    end

    context 'when length is greater than limit' do
      it do
        post '/zero_max', list: [{ key: 'value' }]
        expect(last_response.status).to eq(400)
        expect(last_response.body).to eq('list is expected to have length less than or equal to 0')
      end
    end
  end

  describe '/type_is_not_array' do
    let(:app) do
      Class.new(Grape::API) do
        params do
          requires :list, type: Integer, length: { max: 3 }
        end
        post 'type_is_not_array' do
        end
      end
    end

    context 'does not raise an error' do
      it do
        expect do
          post 'type_is_not_array', list: 12
        end.not_to raise_error
      end
    end
  end

  describe '/type_supports_length' do
    let(:app) do
      Class.new(Grape::API) do
        params do
          requires :list, type: Hash, length: { max: 3 }
        end
        post 'type_supports_length' do
        end
      end
    end

    context 'when length is within limits' do
      it do
        post 'type_supports_length', list: { key: 'value' }
        expect(last_response.status).to eq(201)
        expect(last_response.body).to eq('')
      end
    end

    context 'when length exceeds the limit' do
      it do
        post 'type_supports_length', list: { key: 'value', key1: 'value', key3: 'value', key4: 'value' }
        expect(last_response.status).to eq(400)
        expect(last_response.body).to eq('list is expected to have length less than or equal to 3')
      end
    end
  end

  describe '/negative_min' do
    context 'when min is negative' do
      let(:app) do
        Class.new(Grape::API) do
          params do
            requires :list, type: [Integer], length: { min: -3 }
          end
          post 'negative_min' do
          end
        end
      end

      it 'raises an error' do
        expect { app }.to raise_error(ArgumentError, 'min must be an integer greater than or equal to zero')
      end
    end
  end

  describe '/negative_max' do
    context 'it raises an error' do
      let(:app) do
        Class.new(Grape::API) do
          params do
            requires :list, type: [Integer], length: { max: -3 }
          end
          post 'negative_max' do
          end
        end
      end

      it do
        expect { app }.to raise_error(ArgumentError, 'max must be an integer greater than or equal to zero')
      end
    end
  end

  describe '/float_min' do
    context 'when min is not an integer' do
      let(:app) do
        Class.new(Grape::API) do
          params do
            requires :list, type: [Integer], length: { min: 2.5 }
          end
          post 'float_min' do
          end
        end
      end

      it do
        expect { app }.to raise_error(ArgumentError, 'min must be an integer greater than or equal to zero')
      end
    end
  end

  describe '/float_max' do
    context 'when max is not an integer' do
      let(:app) do
        Class.new(Grape::API) do
          params do
            requires :list, type: [Integer], length: { max: 2.5 }
          end
          post 'float_max' do
          end
        end
      end

      it do
        expect { app }.to raise_error(ArgumentError, 'max must be an integer greater than or equal to zero')
      end
    end
  end

  describe '/min_greater_than_max' do
    context 'raises an error' do
      let(:app) do
        Class.new(Grape::API) do
          params do
            requires :list, type: [Integer], length: { min: 15, max: 3 }
          end
          post 'min_greater_than_max' do
          end
        end
      end

      it do
        expect { app }.to raise_error(ArgumentError, 'min 15 cannot be greater than max 3')
      end
    end
  end

  describe '/min_equal_to_max' do
    let(:app) do
      Class.new(Grape::API) do
        params do
          requires :list, type: [Integer], length: { min: 3, max: 3 }
        end
        post 'min_equal_to_max' do
        end
      end
    end

    context 'when array meets expectations' do
      it do
        post 'min_equal_to_max', list: [1, 2, 3]
        expect(last_response.status).to eq(201)
        expect(last_response.body).to eq('')
      end
    end

    context 'when array is less than min' do
      it do
        post 'min_equal_to_max', list: [1, 2]
        expect(last_response.status).to eq(400)
        expect(last_response.body).to eq('list is expected to have length within 3 and 3')
      end
    end

    context 'when array is greater than max' do
      it do
        post 'min_equal_to_max', list: [1, 2, 3, 4]
        expect(last_response.status).to eq(400)
        expect(last_response.body).to eq('list is expected to have length within 3 and 3')
      end
    end
  end

  describe '/custom-message' do
    let(:app) do
      Class.new(Grape::API) do
        params do
          requires :list, type: [Integer], length: { min: 2, message: 'not match' }
        end
        post '/custom-message' do
        end
      end
    end

    context 'is within limits' do
      it do
        post '/custom-message', list: [1, 2, 3]
        expect(last_response.status).to eq(201)
        expect(last_response.body).to eq('')
      end
    end

    context 'is outside limit' do
      it do
        post '/custom-message', list: [1]
        expect(last_response.status).to eq(400)
        expect(last_response.body).to eq('list not match')
      end
    end
  end

  describe '/is' do
    let(:app) do
      Class.new(Grape::API) do
        params do
          requires :code, length: { is: 2 }
        end
        post 'is' do
        end
      end
    end

    context 'when length is exact' do
      it do
        post 'is', code: 'ZZ'
        expect(last_response.status).to eq(201)
        expect(last_response.body).to eq('')
      end
    end

    context 'when length exceeds the limit' do
      it do
        post 'is', code: 'aze'
        expect(last_response.status).to eq(400)
        expect(last_response.body).to eq('code is expected to have length exactly equal to 2')
      end
    end

    context 'when length is less than the limit' do
      it do
        post 'is', code: 'a'
        expect(last_response.status).to eq(400)
        expect(last_response.body).to eq('code is expected to have length exactly equal to 2')
      end
    end

    context 'when length is zero' do
      it do
        post 'is', code: ''
        expect(last_response.status).to eq(400)
        expect(last_response.body).to eq('code is expected to have length exactly equal to 2')
      end
    end
  end

  describe '/negative_is' do
    let(:app) do
      Class.new(Grape::API) do
        params do
          requires :code, length: { is: -2 }
        end
        post 'negative_is' do
        end
      end
    end

    context 'when `is` is negative' do
      it do
        expect { app }.to raise_error(ArgumentError, 'is must be an integer greater than zero')
      end
    end
  end

  describe '/no_constraints' do
    context 'when no length constraint is specified' do
      let(:app) do
        Class.new(Grape::API) do
          params do
            requires :list, type: [Integer], length: {}
          end
          post 'no_constraints' do
          end
        end
      end

      it do
        expect { app }.to raise_error(ArgumentError, 'at least one of :min, :max, or :is must be specified')
      end
    end
  end

  describe '/is_with_max' do
    context 'when `is` is combined with max' do
      let(:app) do
        Class.new(Grape::API) do
          params do
            requires :code, length: { is: 2, max: 10 }
          end
          post 'is_with_max' do
          end
        end
      end

      it do
        expect { app }.to raise_error(ArgumentError, 'is cannot be combined with min or max')
      end
    end
  end
end
