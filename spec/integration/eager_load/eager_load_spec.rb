# frozen_string_literal: true

$LOAD_PATH.unshift(File.join(File.dirname(__FILE__), '..', '..', 'lib'))
require 'grape'

describe Grape do
  it 'eager_load!' do
    require 'grape/eager_load'
    expect { described_class.eager_load! }.not_to raise_error
  end

  it 'compile!' do
    expect { Class.new(Grape::API).compile! }.not_to raise_error
  end
end
