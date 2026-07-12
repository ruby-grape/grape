# frozen_string_literal: true

RSpec.describe Grape::Mountable do
  it 'marks Grape::API and its subclasses' do
    expect(Grape::API).to be_a(described_class)
    expect(Class.new(Grape::API)).to be_a(described_class)
  end

  it 'marks Grape::API::Instance and mounted instances' do
    expect(Grape::API::Instance).to be_a(described_class)
    expect(Class.new(Grape::API).mount_instance).to be_a(described_class)
  end

  it 'does not mark a bare Rack app' do
    expect(->(_env) { [200, {}, []] }).not_to be_a(described_class)
    expect(Class.new).not_to be_a(described_class)
  end
end
