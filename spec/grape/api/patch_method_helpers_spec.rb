# frozen_string_literal: true

describe Grape::API::Helpers do
  let(:patch_public) do
    Class.new(Grape::API) do
      format :json
      version 'public-v1', using: :header, vendor: 'grape'

      get do
        { ok: 'public' }
      end
    end
  end
  let(:auth_methods) do
    Module.new do
      def authenticate!; end
    end
  end
  let(:patch_private) do
    context = self

    Class.new(Grape::API) do
      format :json
      version 'private-v1', using: :header, vendor: 'grape'

      helpers context.auth_methods

      before do
        authenticate!
      end

      get do
        { ok: 'private' }
      end
    end
  end
  let(:main) do
    context = self

    Class.new(Grape::API) do
      mount context.patch_public
      mount context.patch_private
    end
  end

  def app
    main
  end

  context 'patch' do
    it 'public' do
      patch '/', {}, Grape::Http::Headers::HTTP_ACCEPT => 'application/vnd.grape-public-v1+json'
      expect(last_response.status).to eq 405
    end

    it 'private' do
      patch '/', {}, Grape::Http::Headers::HTTP_ACCEPT => 'application/vnd.grape-private-v1+json'
      expect(last_response.status).to eq 405
    end

    it 'default' do
      patch '/'
      expect(last_response.status).to eq 405
    end
  end

  context 'default' do
    it 'public' do
      get '/', {}, Grape::Http::Headers::HTTP_ACCEPT => 'application/vnd.grape-public-v1+json'
      expect(last_response.status).to eq 200
      expect(last_response.body).to eq({ ok: 'public' }.to_json)
    end

    it 'private' do
      get '/', {}, Grape::Http::Headers::HTTP_ACCEPT => 'application/vnd.grape-private-v1+json'
      expect(last_response.status).to eq 200
      expect(last_response.body).to eq({ ok: 'private' }.to_json)
    end

    it 'default' do
      get '/'
      expect(last_response.status).to eq 200
      expect(last_response.body).to eq({ ok: 'public' }.to_json)
    end
  end
end
