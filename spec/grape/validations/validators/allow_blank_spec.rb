require 'spec_helper'

describe Grape::Validations::AllowBlankValidator do
  module ValidationsSpec
    module AllowBlankValidatorSpec
      class API < Grape::API
        default_format :json

        params do
          requires :name, allow_blank: false
        end
        get

        params do
          optional :name, allow_blank: false
        end
        get '/disallow_blank_optional_param'

        params do
          requires :name, allow_blank: true
        end
        get '/allow_blank'

        params do
          requires :val, type: DateTime, allow_blank: true
        end
        get '/allow_datetime_blank'

        params do
          requires :val, type: DateTime, allow_blank: false
        end
        get '/disallow_datetime_blank'

        params do
          requires :val, type: DateTime
        end
        get '/default_allow_datetime_blank'

        params do
          requires :val, type: Date, allow_blank: true
        end
        get '/allow_date_blank'

        params do
          requires :val, type: Integer, allow_blank: true
        end
        get '/allow_integer_blank'

        params do
          requires :val, type: Float, allow_blank: true
        end
        get '/allow_float_blank'

        params do
          requires :val, type: Fixnum, allow_blank: true
        end
        get '/allow_fixnum_blank'

        params do
          requires :val, type: Symbol, allow_blank: true
        end
        get '/allow_symbol_blank'

        params do
          requires :val, type: Boolean, allow_blank: true
        end
        get '/allow_boolean_blank'

        params do
          requires :val, type: Boolean, allow_blank: false
        end
        get '/disallow_boolean_blank'

        params do
          optional :user, type: Hash do
            requires :name, allow_blank: false
          end
        end
        get '/disallow_blank_required_param_in_an_optional_group'

        params do
          optional :user, type: Hash do
            requires :name, type: Date, allow_blank: true
          end
        end
        get '/allow_blank_date_param_in_an_optional_group'

        params do
          optional :user, type: Hash do
            optional :name, allow_blank: false
            requires :age
          end
        end
        get '/disallow_blank_optional_param_in_an_optional_group'

        params do
          requires :user, type: Hash do
            requires :name, allow_blank: false
          end
        end
        get '/disallow_blank_required_param_in_a_required_group'

        params do
          requires :user, type: Hash do
            requires :name, allow_blank: false
          end
        end
        get '/disallow_string_value_in_a_required_hash_group'

        params do
          requires :user, type: Hash do
            optional :name, allow_blank: false
          end
        end
        get '/disallow_blank_optional_param_in_a_required_group'

        params do
          optional :user, type: Hash do
            optional :name, allow_blank: false
          end
        end
        get '/disallow_string_value_in_an_optional_hash_group'
      end
    end
  end

  def app
    ValidationsSpec::AllowBlankValidatorSpec::API
  end

  context 'invalid input' do
    it 'refuses empty string' do
      get '/', name: ''
      expect(last_response.status).to eq(400)

      get '/disallow_datetime_blank', val: ''
      expect(last_response.status).to eq(400)
    end

    it 'refuses only whitespaces' do
      get '/', name: '   '
      expect(last_response.status).to eq(400)

      get '/', name: "  \n "
      expect(last_response.status).to eq(400)

      get '/', name: "\n"
      expect(last_response.status).to eq(400)
    end

    it 'refuses nil' do
      get '/', name: nil
      expect(last_response.status).to eq(400)
    end
  end

  context 'valid input' do
    it 'accepts valid input' do
      get '/', name: 'bob'
      expect(last_response.status).to eq(200)
    end

    it 'accepts empty input when allow_blank is false' do
      get '/allow_blank', name: ''
      expect(last_response.status).to eq(200)
    end

    it 'accepts empty input' do
      get '/default_allow_datetime_blank', val: ''
      expect(last_response.status).to eq(200)
    end

    it 'accepts empty when datetime allow_blank' do
      get '/allow_datetime_blank', val: ''
      expect(last_response.status).to eq(200)
    end

    it 'accepts empty when date allow_blank' do
      get '/allow_date_blank', val: ''
      expect(last_response.status).to eq(200)
    end

    context 'allow_blank when Numeric' do
      it 'accepts empty when integer allow_blank' do
        get '/allow_integer_blank', val: ''
        expect(last_response.status).to eq(200)
      end

      it 'accepts empty when float allow_blank' do
        get '/allow_float_blank', val: ''
        expect(last_response.status).to eq(200)
      end

      it 'accepts empty when fixnum allow_blank' do
        get '/allow_fixnum_blank', val: ''
        expect(last_response.status).to eq(200)
      end
    end

    it 'accepts empty when symbol allow_blank' do
      get '/allow_symbol_blank', val: ''
      expect(last_response.status).to eq(200)
    end

    it 'accepts empty when boolean allow_blank' do
      get '/allow_boolean_blank', val: ''
      expect(last_response.status).to eq(200)
    end

    it 'accepts false when boolean allow_blank' do
      get '/disallow_boolean_blank', val: false
      expect(last_response.status).to eq(200)
    end
  end

  context 'in an optional group' do
    context 'as a required param' do
      it 'accepts a missing group, even with a disallwed blank param' do
        get '/disallow_blank_required_param_in_an_optional_group'
        expect(last_response.status).to eq(200)
      end

      it 'accepts a nested missing date value' do
        get '/allow_blank_date_param_in_an_optional_group', user: { name: '' }
        expect(last_response.status).to eq(200)
      end

      it 'refuses a blank value in an existing group' do
        get '/disallow_blank_required_param_in_an_optional_group', user: { name: '' }
        expect(last_response.status).to eq(400)
      end
    end

    context 'as an optional param' do
      it 'accepts a missing group, even with a disallwed blank param' do
        get '/disallow_blank_optional_param_in_an_optional_group'
        expect(last_response.status).to eq(200)
      end

      it 'accepts a nested missing optional value' do
        get '/disallow_blank_optional_param_in_an_optional_group', user: { age: '29' }
        expect(last_response.status).to eq(200)
      end

      it 'refuses a blank existing value in an existing scope' do
        get '/disallow_blank_optional_param_in_an_optional_group', user: { age: '29', name: '' }
        expect(last_response.status).to eq(400)
      end
    end
  end

  context 'in a required group' do
    context 'as a required param' do
      it 'refuses a blank value in a required existing group' do
        get '/disallow_blank_required_param_in_a_required_group', user: { name: '' }
        expect(last_response.status).to eq(400)
      end

      it 'refuses a string value in a required hash group' do
        get '/disallow_string_value_in_a_required_hash_group', user: ''
        expect(last_response.status).to eq(400)
      end
    end

    context 'as an optional param' do
      it 'accepts a nested missing value' do
        get '/disallow_blank_optional_param_in_a_required_group', user: { age: '29' }
        expect(last_response.status).to eq(200)
      end

      it 'refuses a blank existing value in an existing scope' do
        get '/disallow_blank_optional_param_in_a_required_group', user: { age: '29', name: '' }
        expect(last_response.status).to eq(400)
      end

      it 'refuses a string value in an optional hash group' do
        get '/disallow_string_value_in_an_optional_hash_group', user: ''
        expect(last_response.status).to eq(400)
      end
    end
  end
end
