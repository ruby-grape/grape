require 'spec_helper'

module CustomValidations  
  class Customvalidator < Grape::Validations::Validator
    def validate_param!(attr_name, params)
      unless params[attr_name] == 'im custom'
        throw :error, :status => 400, :message => "#{attr_name}: is not custom!"
      end    
    end
  end  
end   

describe Grape::API do
  subject { Class.new(Grape::API) }
  def app; subject end

  describe 'params' do
    it 'validates optional parameter if present' do
      subject.params { optional :a_number, :regexp => /^[0-9]+$/ }
      subject.get '/optional' do 'optional works!'; end

      get '/optional', { :a_number => 'string' }
      last_response.status.should == 400
      last_response.body.should == 'invalid parameter: a_number'

      get '/optional', { :a_number => 45 }
      last_response.status.should == 200
      last_response.body.should == 'optional works!'
    end

    context 'when using optional with a custom validator' do
      before do
        subject.params { optional :custom, :customvalidator => true }
        subject.get '/optional_custom' do 'optional with custom works!'; end 
      end

      it 'validates when param is present' do
        get '/optional_custom', { :custom => 'im custom' }
        last_response.status.should == 200
        last_response.body.should == 'optional with custom works!'

        get '/optional_custom', { :custom => 'im wrong' }
        last_response.status.should == 400
        last_response.body.should == 'custom: is not custom!'
      end

      it "skip validation when parameter isn't present" do
        get '/optional_custom'
        last_response.status.should == 200
        last_response.body.should == 'optional with custom works!'
      end

      it 'validates with custom validator when param present and incorrect type' do
        subject.params { optional :custom, :type => String, :customvalidator => true }
    
        get '/optional_custom', { :custom => 123 }
        last_response.status.should == 400
        last_response.body.should == 'custom: is not custom!'
      end
    end

    context 'when using requires with a custom validator' do
      before do
        subject.params { requires :custom, :customvalidator => true }
        subject.get '/required_custom' do 'required with custom works!'; end
      end

      it 'validates when param is present' do
        get '/required_custom', { :custom => 'im wrong, validate me' }
        last_response.status.should == 400
        last_response.body.should == 'custom: is not custom!'

        get '/required_custom', { :custom => 'im custom' }
        last_response.status.should == 200
        last_response.body.should == 'required with custom works!'
      end

      it 'validates when param is not present' do
        get '/required_custom'
        last_response.status.should == 400
        last_response.body.should == 'custom: is not custom!'
      end
    end
  end
end
