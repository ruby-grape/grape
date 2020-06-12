# frozen_string_literal: true

$LOAD_PATH.unshift(File.join(File.dirname(__FILE__), '..', '..', 'lib'))
require 'grape'
require 'grape/eager_load'

describe 'eager loading' do
  class API < Grape::API
  end

  it 'loads successfully' do
    expect { Grape.eager_load! }.to_not raise_error
    expect { API.compile! }.to_not raise_error
  end
end
