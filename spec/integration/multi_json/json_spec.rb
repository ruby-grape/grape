# frozen_string_literal: true

# grape_entity depends on multi-json and it breaks the test.
describe Grape::Json, if: defined?(::MultiJson) && !defined?(Grape::Entity) do
  subject { described_class }

  it { is_expected.to eq(::MultiJson) }
end
