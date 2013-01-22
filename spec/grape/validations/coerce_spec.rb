# encoding: utf-8
require 'spec_helper'

describe Grape::Validations::CoerceValidator do
  subject { Class.new(Grape::API) }
  def app; subject end

  describe 'coerce' do
    it "i18n error on malformed input" do
      I18n.load_path << File.expand_path('../zh-CN.yml',__FILE__)
      I18n.reload!
      I18n.locale = :'zh-CN'
      subject.params { requires :age, :type => Integer }
      subject.get '/single' do 'int works'; end

      get '/single', :age => '43a'
      last_response.status.should == 400
      last_response.body.should == '年龄格式不正确'
      I18n.locale = :en

    end
    it 'error on malformed input' do
      subject.params { requires :int, :type => Integer }
      subject.get '/single' do 'int works'; end

      get '/single', :int => '43a'
      last_response.status.should == 400
      last_response.body.should == 'invalid parameter: int'

      get '/single', :int => '43'
      last_response.status.should == 200
      last_response.body.should == 'int works'
    end

    it 'error on malformed input (Array)' do
      subject.params { requires :ids, :type => Array[Integer] }
      subject.get '/array' do 'array int works'; end

      get 'array', { :ids => ['1', '2', 'az'] }
      last_response.status.should == 400
      last_response.body.should == 'invalid parameter: ids'

      get 'array', { :ids => ['1', '2', '890'] }
      last_response.status.should == 200
      last_response.body.should == 'array int works'
    end

    context 'complex objects' do
      module CoerceValidatorSpec
        class User
          include Virtus
          attribute :id, Integer
          attribute :name, String
        end
      end

      it 'error on malformed input for complex objects' do
        subject.params { requires :user, :type => CoerceValidatorSpec::User }
        subject.get '/user' do 'complex works'; end

        get '/user', :user => "32"
        last_response.status.should == 400
        last_response.body.should == 'invalid parameter: user'

        get '/user', :user => { :id => 32, :name => 'Bob' }
        last_response.status.should == 200
        last_response.body.should == 'complex works'
      end
    end

    context 'coerces' do
      it 'Integer' do
        subject.params { requires :int, :coerce => Integer }
        subject.get '/int' do params[:int].class; end

        get '/int', { :int => "45" }
        last_response.status.should == 200
        last_response.body.should == 'Fixnum'
      end

      it 'Array of Integers' do
        subject.params { requires :arry, :coerce => Array[Integer] }
        subject.get '/array' do params[:arry][0].class; end

        get '/array', { :arry => [ '1', '2', '3' ] }
        last_response.status.should == 200
        last_response.body.should == 'Fixnum'
      end

      it 'Array of Bools' do
        subject.params { requires :arry, :coerce => Array[Virtus::Attribute::Boolean] }
        subject.get '/array' do params[:arry][0].class; end

        get 'array', { :arry => [1, 0] }
        last_response.status.should == 200
        last_response.body.should == 'TrueClass'
      end

      it 'Bool' do
        subject.params { requires :bool, :coerce => Virtus::Attribute::Boolean }
        subject.get '/bool' do params[:bool].class; end

        get '/bool', { :bool => 1 }
        last_response.status.should == 200
        last_response.body.should == 'TrueClass'

        get '/bool', { :bool => 0 }
        last_response.status.should == 200
        last_response.body.should == 'FalseClass'

        get '/bool', { :bool => 'false' }
        last_response.status.should == 200
        last_response.body.should == 'FalseClass'

        get '/bool', { :bool => 'true' }
        last_response.status.should == 200
        last_response.body.should == 'TrueClass'
      end

      it 'file' do
        subject.params { requires :file, :coerce => Rack::Multipart::UploadedFile }
        subject.post '/upload' do params[:file].filename; end

        post '/upload', { :file => Rack::Test::UploadedFile.new(__FILE__) }
        last_response.status.should == 201
        last_response.body.should == File.basename(__FILE__).to_s
      end

      it 'Nests integers' do
        subject.params do
          group :integers do
            requires :int, :coerce => Integer
          end
        end
        subject.get '/int' do params[:integers][:int].class; end

        get '/int', { :integers => { :int => "45" } }
        last_response.status.should == 200
        last_response.body.should == 'Fixnum'
      end
    end
  end
end
