require 'spec_helper'
require 'sidekiq/testing'

describe 'ProviderTemplate' do
  it 'implements .first to return string' do
    expect(ProviderTemplate.first).to be_an_instance_of(String)
  end

  it 'implements .last to return string' do
    expect(ProviderTemplate.last).to be_an_instance_of(String)
  end

  it 'implements .to_a to return array' do
    expect(ProviderTemplate.to_a).to be_an_instance_of(Array)
  end

  it 'returns some templates when all is invoked' do
    expect(ProviderTemplate.all.length).to be > 0
  end

  it 'allows testing for image presence' do
    expect_any_instance_of(ProviderTemplate).to(
      receive(:templates).and_return(['my_cluster.my_image'])
    )

    expect(ProviderTemplate.include_image?('my_image')).to be true
  end
end
