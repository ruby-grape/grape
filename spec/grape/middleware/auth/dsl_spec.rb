# frozen_string_literal: true

describe Grape::Middleware::Auth::DSL do
  subject { Class.new(Grape::API) }

  let(:block) { -> {} }
  # #auth records whatever it is given; the strategy behind the label is looked
  # up when the middleware is built. A label with no built-in sugar method keeps
  # that distinction visible.
  let(:settings) do
    {
      opaque: 'secret',
      proc: block,
      realm: 'API Authorization',
      type: :custom
    }
  end

  describe '.auth' do
    it 'sets auth parameters' do
      expect(subject.base_instance).to receive(:use).with(Grape::Middleware::Auth::Base, settings)

      subject.auth :custom, realm: settings[:realm], opaque: settings[:opaque], &settings[:proc]
      expect(subject.auth).to eq(settings)
    end

    it 'can be called multiple times' do
      expect(subject.base_instance).to receive(:use).with(Grape::Middleware::Auth::Base, settings)
      expect(subject.base_instance).to receive(:use).with(Grape::Middleware::Auth::Base, settings.merge(realm: 'super_secret'))

      subject.auth :custom, realm: settings[:realm], opaque: settings[:opaque], &settings[:proc]
      first_settings = subject.auth

      subject.auth :custom, realm: 'super_secret', opaque: settings[:opaque], &settings[:proc]

      expect(subject.auth).to eq(settings.merge(realm: 'super_secret'))
      expect(subject.auth.object_id).not_to eq(first_settings.object_id)
    end
  end

  describe '.http_basic' do
    it 'sets auth parameters' do
      subject.http_basic realm: 'my_realm', &settings[:proc]
      expect(subject.auth).to eq(realm: 'my_realm', type: :http_basic, proc: block)
    end
  end

  describe 'a positional options Hash' do
    it 'is rejected by `auth` -- options are keyword arguments' do
      expect { subject.auth :custom, { realm: 'r', opaque: 'o' }, &block }.to raise_error(ArgumentError)
    end

    it 'is rejected by `http_basic` -- options are keyword arguments' do
      expect { subject.http_basic({ realm: 'my_realm' }, &block) }.to raise_error(ArgumentError)
    end
  end
end
