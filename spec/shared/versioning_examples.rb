shared_examples_for 'versioning' do
  it 'sets the API version' do
    subject.version 'v1', macro_options
    subject.get :hello do
      "Version: #{request.env['api.version']}"
    end
    versioned_get '/hello', 'v1', macro_options
    last_response.body.should eql "Version: v1"
  end

  it 'adds the prefix before the API version' do
    subject.prefix 'api'
    subject.version 'v1', macro_options
    subject.get :hello do
      "Version: #{request.env['api.version']}"
    end
    versioned_get '/hello', 'v1', macro_options.merge(:prefix => 'api')
    last_response.body.should eql "Version: v1"
  end

  it 'is able to specify version as a nesting' do
    subject.version 'v2', macro_options
    subject.get '/awesome' do
      "Radical"
    end

    subject.version 'v1', macro_options do
      get '/legacy' do
        "Totally"
      end
    end

    versioned_get '/awesome', 'v1', macro_options
    last_response.status.should eql 404

    versioned_get '/awesome', 'v2', macro_options
    last_response.status.should eql 200
    versioned_get '/legacy', 'v1', macro_options
    last_response.status.should eql 200
    versioned_get '/legacy', 'v2', macro_options
    last_response.status.should eql 404
  end

  it 'is able to specify multiple versions' do
    subject.version 'v1', 'v2', macro_options
    subject.get 'awesome' do
      "I exist"
    end

    versioned_get '/awesome', 'v1', macro_options
    last_response.status.should eql 200
    versioned_get '/awesome', 'v2', macro_options
    last_response.status.should eql 200
    versioned_get '/awesome', 'v3', macro_options
    last_response.status.should eql 404
  end

  context 'with different versions for the same endpoint' do
    context 'without a prefix' do
      it 'allows the same endpoint to be implemented' do
        subject.version 'v2', macro_options
        subject.get 'version' do
          request.env['api.version']
        end

        subject.version 'v1', macro_options do
          get 'version' do
            "version " + request.env['api.version']
          end
        end

        versioned_get '/version', 'v2', macro_options
        last_response.status.should == 200
        last_response.body.should == 'v2'
        versioned_get '/version', 'v1', macro_options
        last_response.status.should == 200
        last_response.body.should == 'version v1'
      end
    end

    context 'with a prefix' do
      it 'allows the same endpoint to be implemented' do
        subject.prefix 'api'
        subject.version 'v2', macro_options
        subject.get 'version' do
          request.env['api.version']
        end

        subject.version 'v1', macro_options do
          get 'version' do
            "version " + request.env['api.version']
          end
        end

        versioned_get '/api/version', 'v2', macro_options
        last_response.status.should == 200
        last_response.body.should == 'v2'
        versioned_get '/api/version', 'v1', macro_options
        last_response.status.should == 200
        last_response.body.should == 'version v1'
      end
    end
  end
end
