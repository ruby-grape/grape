# frozen_string_literal: true

RSpec.shared_examples 'deprecated class' do
  subject { deprecated_class.new }

  around do |example|
    old_deprec_behavior = ActiveSupport::Deprecation.behavior
    ActiveSupport::Deprecation.behavior = :raise
    example.run
    ActiveSupport::Deprecation.behavior = old_deprec_behavior
  end

  it 'raises an ActiveSupport::DeprecationException' do
    expect { subject }.to raise_error(ActiveSupport::DeprecationException)
  end
end
