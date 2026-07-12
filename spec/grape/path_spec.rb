# frozen_string_literal: true

RSpec.describe 'Grape::Path' do
  it 'is deprecated and points at Grape::Router::Pattern::Path' do
    expect { Grape::Path.new(nil, nil, {}) }.to raise_error(
      ActiveSupport::DeprecationException, /Grape::Path is deprecated.*Grape::Router::Pattern::Path/m
    )
  end
end
