require 'spec_helper'

describe Grape::Validations do
  subject { Class.new(Grape::API) }
  def app; subject end

  describe 'params' do
    context 'optional' do
      it 'validates when params is present' do
        subject.params { optional :a_number, :regexp => /^[0-9]+$/ }
        subject.get '/optional' do 'optional works!'; end

        get '/optional', { :a_number => 'string' }
        last_response.status.should == 400
        last_response.body.should == 'invalid parameter: a_number'

        get '/optional', { :a_number => 45 }
        last_response.status.should == 200
        last_response.body.should == 'optional works!'
      end

      it "doesn't validate when param not present" do
        subject.params { optional :a_number, :regexp => /^[0-9]+$/ }
        subject.get '/optional' do 'optional works!'; end

        get '/optional'
        last_response.status.should == 200
        last_response.body.should == 'optional works!'
      end

      it 'adds to declared parameters' do
        subject.params { optional :some_param }
        subject.settings[:declared_params].should == [:some_param]
      end
    end

    context 'required' do
      before do
        subject.params { requires :key }
        subject.get '/required' do 'required works'; end
      end

      it 'errors when param not present' do
        get '/required'
        last_response.status.should == 400
        last_response.body.should == 'missing parameter: key'
      end

      it "doesn't throw a missing param when param is present" do
        get '/required', { :key => 'cool' }
        last_response.status.should == 200
        last_response.body.should == 'required works'
      end

      it 'adds to declared parameters' do
        subject.params { requires :some_param }
        subject.settings[:declared_params].should == [:some_param]
      end
    end

    context 'group' do
      before do
        subject.params {
          group :items do
            requires :key
          end
        }
        subject.get '/required' do 'required works'; end
      end

      it 'errors when param not present' do
        get '/required'
        last_response.status.should == 400
        last_response.body.should == 'missing parameter: items[key]'
      end

      it "doesn't throw a missing param when param is present" do
        get '/required', { :items => [:key => 'hello', :key => 'world'] }
        last_response.status.should == 200
        last_response.body.should == 'required works'
      end

      it 'adds to declared parameters' do
        subject.params {
          group :items do
            requires :key
          end
        }
        subject.settings[:declared_params].should == [:items => [:key]]
      end
    end

    context 'custom validation' do
      module CustomValidations
        class Customvalidator < Grape::Validations::Validator
          def validate_param!(attr_name, params)
            unless params[attr_name] == 'im custom'
              throw :error, :status => 400, :message => "#{attr_name}: is not custom!"
            end
          end
        end
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

        it "skips validation when parameter isn't present" do
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
          last_response.body.should == 'missing parameter: custom'
        end

        context 'nested namespaces' do
          before do
            subject.params { requires :custom, :customvalidator => true }
            subject.namespace 'nested' do
              get 'one' do 'validation failed' end
              namespace 'nested' do
                get 'two' do 'validation failed' end
              end
            end
            subject.namespace 'peer' do
              get 'one' do 'no validation required' end
              namespace 'nested' do
                get 'two' do 'no validation required' end
              end
            end

            subject.namespace 'unrelated' do
              params{ requires :name }
              get 'one' do 'validation required'; end

              namespace 'double' do
                get 'two' do 'no validation required' end
              end
            end
          end

          specify 'the parent namespace uses the validator' do
            get '/nested/one', { :custom => 'im wrong, validate me'}
            last_response.status.should == 400
            last_response.body.should == 'custom: is not custom!'
          end

          specify 'the nested namesapce inherits the custom validator' do
            get '/nested/nested/two', { :custom => 'im wrong, validate me'}
            last_response.status.should == 400
            last_response.body.should == 'custom: is not custom!'
          end

          specify 'peer namesapces does not have the validator' do
            get '/peer/one', { :custom => 'im not validated' }
            last_response.status.should == 200
            last_response.body.should == 'no validation required'
          end

          specify 'namespaces nested in peers should also not have the validator' do
            get '/peer/nested/two', { :custom => 'im not validated' }
            last_response.status.should == 200
            last_response.body.should == 'no validation required'
          end

          specify 'when nested, specifying a route should clear out the validations for deeper nested params' do
            get '/unrelated/one'
            last_response.status.should == 400
            get '/unrelated/double/two'
            last_response.status.should == 200
          end
        end
      end
    end # end custom validation
  end
end
