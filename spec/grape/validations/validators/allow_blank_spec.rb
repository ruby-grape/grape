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
          optional :user, type: Hash do
            requires :name, allow_blank: false
          end
        end
        get '/disallow_blank_required_param_in_an_optional_group'

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
            optional :name, allow_blank: false
          end
        end
        get '/disallow_blank_optional_param_in_a_required_group'
      end
    end
  end

  def app
    ValidationsSpec::AllowBlankValidatorSpec::API
  end

  context 'invalid input' do
    it 'refuses empty string' do
      get '/', name: ""
      expect(last_response.status).to eq(400)
    end

    it 'refuses only whitespaces' do
      get '/', name: "   "
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
      get '/', name: "bob"
      expect(last_response.status).to eq(200)
    end

    it 'accepts empty input when allow_blank is false' do
      get '/allow_blank', name: ""
      expect(last_response.status).to eq(200)
    end
  end

  context 'in an optional group' do
    context 'as a required param' do
      it 'accepts a missing group, even with a disallwed blank param' do
        get '/disallow_blank_required_param_in_an_optional_group'
        expect(last_response.status).to eq(200)
      end

      it 'refuses a blank value in an existing group' do
        get '/disallow_blank_required_param_in_an_optional_group', user: { name: "" }
        expect(last_response.status).to eq(400)
      end
    end

    context 'as an optional param' do
      it 'accepts a missing group, even with a disallwed blank param' do
        get '/disallow_blank_optional_param_in_an_optional_group'
        expect(last_response.status).to eq(200)
      end

      it 'accepts a nested missing optional value' do
        get '/disallow_blank_optional_param_in_an_optional_group', user: { age: "29" }
        expect(last_response.status).to eq(200)
      end

      it 'refuses a blank existing value in an existing scope' do
        get '/disallow_blank_optional_param_in_an_optional_group', user: { age: "29", name: "" }
        expect(last_response.status).to eq(400)
      end
    end
  end

  context 'in a required group' do
    context 'as a required param' do
      it 'refuses a blank value in a required existing group' do
        get '/disallow_blank_required_param_in_a_required_group', user: { name: "" }
        expect(last_response.status).to eq(400)
      end
    end

    context 'as an optional param' do
      it 'accepts a nested missing value' do
        get '/disallow_blank_optional_param_in_a_required_group', user: { age: "29" }
        expect(last_response.status).to eq(200)
      end

      it 'refuses a blank existing value in an existing scope' do
        get '/disallow_blank_optional_param_in_a_required_group', user: { age: "29", name: "" }
        expect(last_response.status).to eq(400)
      end
    end
  end
end
