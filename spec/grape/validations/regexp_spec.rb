require 'spec_helper'

describe Grape::Validations::RegexpValidator do
  module ValidationsSpec
    module RegexpValidatorSpec
      class API < Grape::API
        default_format :json

        params do
          requires :name, regexp: /^[a-z]+$/
        end
        get do

        end
      end
    end
  end

  def app
    ValidationsSpec::RegexpValidatorSpec::API
  end

  it 'refuses invalid input' do
    get '/', name: "invalid name"
    last_response.status.should == 400
  end

  it 'accepts valid input' do
    get '/', name: "bob"
    last_response.status.should == 200
  end

end
