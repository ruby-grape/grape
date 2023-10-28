# frozen_string_literal: true

$LOAD_PATH.unshift(File.join(File.dirname(__FILE__), '..', '..', 'lib'))
require 'grape'

describe Grape do
  it 'compile!' do
    expect { Class.new(Grape::API).compile! }.not_to raise_error
  end
end
